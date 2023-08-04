import NFTContract from 0x01
import Token from 0x01
import FungibleToken from 0x01
import NonFungibleToken from 0x01

pub contract NFTMarketplace
{
    pub resource interface SaleCollectionPublic
    {
        pub fun getIDs(): [UInt64];
        pub fun getPrice(id: UInt64): UFix64;
        pub fun purchase(id: UInt64, recipientCollection: &NonFungibleToken.Collection{NonFungibleToken.CollectionPublic}, payment: @Token.Vault);
    }

    pub resource SaleCollection: SaleCollectionPublic
    {
        pub var forSale: {UInt64: UFix64};
        pub let NFTCollection: Capability<&NFTContract.Collection>;
        pub let TokenVault: Capability<&Token.Vault{FungibleToken.Receiver}>;

        pub fun listForSale(id: UInt64, price: UFix64)
        {
            pre 
            {
                price >= 0.0 : "Price can't be less than 0";
                self.NFTCollection.borrow()!.getIDs().contains(id) : "This NFT is not avaialbe";
            }

            self.forSale[id] = price;
        }

        pub fun unlistFromSale(id: UInt64)
        {
            self.forSale.remove(key: id);
        }

        pub fun purchase(id: UInt64, recipientCollection: &NonFungibleToken.Collection{NonFungibleToken.CollectionPublic}, payment: @Token.Vault)
        {
            pre 
            {
                payment.balance == self.forSale[id]: "The payment is not equal to the price of the NFT";
            }
            
            recipientCollection.deposit(token: <- self.NFTCollection.borrow()!.withdraw(withdrawID: id));
            self.TokenVault.borrow()!.deposit(from: <- payment);
        }

        pub fun getPrice(id: UInt64): UFix64
        {
            return self.forSale[id]!;
        }

        pub fun getIDs(): [UInt64]
        {
            return self.forSale.keys;
        }

        init(nftCollection: Capability<&NFTContract.Collection>, tokenVault: Capability<&Token.Vault{FungibleToken.Receiver}>)
        {
            self.forSale = {};
            self.NFTCollection = nftCollection;
            self.TokenVault = tokenVault;
        }
    }

    pub fun createSaleCollection(nftCollection: Capability<&NFTContract.Collection>, tokenVault: Capability<&Token.Vault{FungibleToken.Receiver}>) : @SaleCollection
    {
        return <- create SaleCollection(nftCollection: nftCollection, tokenVault: tokenVault);
    }

    init()
    {

    }
}