import NonFungibleToken from 0x01;
import NFTContract from 0x01;
import NFTMarketplace from 0x01;
import Token from 0x01;
import FungibleToken from 0x01;

transaction(id: UInt64, price: UFix64)
{
    prepare(acct: AuthAccount)
    {
        let saleCollection = acct.borrow<&NFTMarketplace.SaleCollection>(from: NFTContract.SaleCollectionStoragePath) ?? panic("No sale collection found");

        saleCollection.listForSale(id: id, price: price);
    }
}