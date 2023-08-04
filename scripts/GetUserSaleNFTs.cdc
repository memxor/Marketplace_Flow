import NFTContract from 0x01;
import NonFungibleToken from 0x01;
import NFTMarketplace from 0x01;

pub fun main(account: Address): {UInt64: {UFix64: &NonFungibleToken.NFT}}
{
    let saleCollection = getAccount(account).getCapability(NFTContract.SaleCollectionPublicPath)
                    .borrow<&NFTMarketplace.SaleCollection{NFTMarketplace.SaleCollectionPublic}>()
                    ?? panic("Sale Collection not found");

    let collection = getAccount(account).getCapability(NFTContract.CollectionPublicPath)
                .borrow<&NFTContract.Collection{NonFungibleToken.CollectionPublic, NFTContract.NFTContractCollectionPublic}>()
                ?? panic("Collection not found");

    let returnVals: {UInt64: {UFix64: &NonFungibleToken.NFT}} = {};

    let ids = saleCollection.getIDs();
    for id in ids
    {
        let price = saleCollection.getPrice(id: id);
        let nftRef = collection.borrowNFT(id: id);

        returnVals.insert(key: nftRef.id, {price: nftRef});
    }

    return returnVals;
}