import NFTContract from 0x01;

transaction(name: String, description: String, thumbnail: String)
{
    prepare(acct: AuthAccount)
    {
        let collection = acct.borrow<&NFTContract.Collection>(from: NFTContract.CollectionStoragePath) ?? panic("No collection found");

        let minter = acct.borrow<&NFTContract.NFTMinter>(from: NFTContract.MinterStoragePath) ?? panic("No minter found");
        minter.mintNFT(recipient: collection, name: name, description: description, thumbnail: thumbnail, royalties: [])
    }
}