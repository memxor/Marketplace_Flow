import NFTContract from 0x01
import NonFungibleToken from 0x01

transaction 
{
  prepare(acct: AuthAccount) 
  {
    acct.save(<- NFTContract.createEmptyCollection(), to: NFTContract.CollectionStoragePath);
    acct.link<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic, NonFungibleToken.CollectionPublic}>(NFTContract.CollectionPublicPath, target: NFTContract.CollectionStoragePath);
  }
}