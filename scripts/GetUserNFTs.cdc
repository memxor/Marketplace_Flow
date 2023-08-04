import NFTContract from 0x01;
import NonFungibleToken from 0x01;

pub fun main(account: Address): [&NonFungibleToken.NFT] 
{
  let collection = getAccount(account).getCapability(NFTContract.CollectionPublicPath)
                    .borrow<&NFTContract.Collection{NonFungibleToken.CollectionPublic, NFTContract.NFTContractCollectionPublic}>()
                    ?? panic("Collection not found");

  let returnVals: [&NonFungibleToken.NFT] = [];

  let ids = collection.getIDs();
  for id in ids
  {
    returnVals.append(collection.borrowNFT(id: id));
  }

  return returnVals;
}