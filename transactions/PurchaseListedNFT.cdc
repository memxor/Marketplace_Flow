import NFTMarketplace from 0x01;
import NFTContract from 0x01;
import NonFungibleToken from 0x01;
import Token from 0x01;

transaction(account: Address, id: UInt64)
{
    prepare(acct: AuthAccount)
    {
        let saleCollection = getAccount(account).getCapability(NFTContract.SaleCollectionPublicPath)
                .borrow<&NFTMarketplace.SaleCollection{NFTMarketplace.SaleCollectionPublic}>()
                ?? panic("Sale Collection not found");

        let recipientCollection = getAccount(acct.address).getCapability(NFTContract.CollectionPublicPath)
            .borrow<&NonFungibleToken.Collection{NonFungibleToken.CollectionPublic}>()
            ?? panic("Collection not found");

        let price = saleCollection.getPrice(id: id);
        let payment <- acct.borrow<&Token.Vault>(from: Token.VaultStoragePath)!.withdraw(amount: price) as! @Token.Vault;

        saleCollection.purchase(id: id, recipientCollection: recipientCollection, payment: <- payment);
    }
}