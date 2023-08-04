import FungibleToken from 0x01;
import MetadataViews from 0x01;
import FungibleTokenMetadataViews from 0x01;

pub contract Token: FungibleToken 
{
    pub var totalSupply: UFix64;

    pub let VaultStoragePath: StoragePath;
    pub let VaultPublicPath: PublicPath;
    pub let ReceiverPublicPath: PublicPath;
    pub let AdminStoragePath: StoragePath;


    pub event TokensInitialized(initialSupply: UFix64);
    pub event TokensWithdrawn(amount: UFix64, from: Address?);
    pub event TokensDeposited(amount: UFix64, to: Address?);
    pub event TokensMinted(amount: UFix64);
    pub event TokensBurned(amount: UFix64);
    pub event MinterCreated(allowedAmount: UFix64);
    pub event BurnerCreated();
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver 
    {
        pub var balance: UFix64;

        init(balance: UFix64) 
        {
            self.balance = balance;
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault 
        {
            self.balance = self.balance - amount;
            emit TokensWithdrawn(amount: amount, from: self.owner?.address);
            return <-create Vault(balance: amount);
        }

        pub fun deposit(from: @FungibleToken.Vault) 
        {
            let vault <- from as! @Token.Vault;
            self.balance = self.balance + vault.balance;
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address);
            vault.balance = 0.0;
            destroy vault;
        }

        destroy() 
        {
            if self.balance > 0.0 
            {
                Token.totalSupply = Token.totalSupply - self.balance;
            }
        }

        pub fun getViews(): [Type] {
            return [
                Type<FungibleTokenMetadataViews.FTView>(),
                Type<FungibleTokenMetadataViews.FTDisplay>(),
                Type<FungibleTokenMetadataViews.FTVaultData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view 
            {
                case Type<FungibleTokenMetadataViews.FTView>():
                    return FungibleTokenMetadataViews.FTView(
                        ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                        ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                    )
                case Type<FungibleTokenMetadataViews.FTDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    let medias = MetadataViews.Medias([media])
                    return FungibleTokenMetadataViews.FTDisplay(
                        name: "Example Fungible Token",
                        symbol: "EFT",
                        description: "This fungible token is used as an example to help you develop your next FT #onFlow.",
                        externalURL: MetadataViews.ExternalURL("https://example-ft.onflow.org"),
                        logos: medias,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                        }
                    )
                case Type<FungibleTokenMetadataViews.FTVaultData>():
                    return FungibleTokenMetadataViews.FTVaultData(
                        storagePath: Token.VaultStoragePath,
                        receiverPath: Token.ReceiverPublicPath,
                        metadataPath: Token.VaultPublicPath,
                        providerPath: /private/exampleTokenVault,
                        receiverLinkedType: Type<&Token.Vault{FungibleToken.Receiver}>(),
                        metadataLinkedType: Type<&Token.Vault{FungibleToken.Balance, MetadataViews.Resolver}>(),
                        providerLinkedType: Type<&Token.Vault{FungibleToken.Provider}>(),
                        createEmptyVaultFunction: (fun (): @Token.Vault {
                            return <-Token.createEmptyVault()
                        })
                    )
            }
            return nil
        }
    }

    pub fun createEmptyVault(): @Vault 
    {
        return <-create Vault(balance: 0.0);
    }

    pub resource Administrator 
    {
        pub fun createNewMinter(allowedAmount: UFix64): @Minter 
        {
            emit MinterCreated(allowedAmount: allowedAmount);
            return <-create Minter(allowedAmount: allowedAmount);
        }

        pub fun createNewBurner(): @Burner 
        {
            emit BurnerCreated();
            return <-create Burner();
        }
    }

    pub resource Minter 
    {
        pub var allowedAmount: UFix64;

        pub fun mintTokens(amount: UFix64): @Token.Vault 
        {
            pre 
            {
                amount > 0.0: "Amount minted must be greater than zero";
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount";
            }
            Token.totalSupply = Token.totalSupply + amount;
            self.allowedAmount = self.allowedAmount - amount;
            emit TokensMinted(amount: amount);
            return <-create Vault(balance: amount);
        }

        init(allowedAmount: UFix64) 
        {
            self.allowedAmount = allowedAmount;
        }
    }

    pub resource Burner 
    {
        pub fun burnTokens(from: @FungibleToken.Vault) 
        {
            let vault <- from as! @Token.Vault;
            let amount = vault.balance;
            destroy vault;
            emit TokensBurned(amount: amount);
        }
    }

    init() {
        self.totalSupply = 1000.0;
        self.VaultStoragePath = /storage/exampleTokenVault;
        self.VaultPublicPath = /public/exampleTokenMetadata;
        self.ReceiverPublicPath = /public/exampleTokenReceiver;
        self.AdminStoragePath = /storage/exampleTokenAdmin;

        let vault <- create Vault(balance: self.totalSupply);
        self.account.save(<-vault, to: self.VaultStoragePath);

        self.account.link<&{FungibleToken.Receiver}>(
            self.ReceiverPublicPath,
            target: self.VaultStoragePath
        )

        self.account.link<&Token.Vault{FungibleToken.Balance}>(
            self.VaultPublicPath,
            target: self.VaultStoragePath
        )

        let admin <- create Administrator();
        self.account.save(<-admin, to: self.AdminStoragePath);

        emit TokensInitialized(initialSupply: self.totalSupply);
    }
}