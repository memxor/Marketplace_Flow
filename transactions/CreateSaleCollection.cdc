import NonFungibleToken from 0x01;
import NFTContract from 0x01;
import NFTMarketplace from 0x01;
import Token from 0x01;
import FungibleToken from 0x01;

transaction
{
    prepare(acct: AuthAccount)
    {
        let nftCollection = acct.getCapability<&NFTContract.Collection>(NFTContract.CollectionPublicPath);
        let tokenVault = acct.getCapability<&Token.Vault{FungibleToken.Receiver}>(Token.ReceiverPublicPath);
        acct.save(<- NFTMarketplace.createSaleCollection(nftCollection: nftCollection, tokenVault: tokenVault), to: NFTContract.SaleCollectionStoragePath);
        acct.link<&NFTMarketplace.SaleCollection{NFTMarketplace.SaleCollectionPublic}>(NFTContract.SaleCollectionPublicPath, target: NFTContract.SaleCollectionStoragePath)
    }
}