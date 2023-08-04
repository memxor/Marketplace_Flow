import NonFungibleToken from 0x01;
import MetadataViews from 0x01;
import ViewResolver from 0x01;

pub contract NFTContract: NonFungibleToken, ViewResolver
{
  pub var totalSupply: UInt64;

  pub event ContractInitialized();
  pub event Withdraw(id: UInt64, from: Address?);
  pub event Deposit(id: UInt64, to: Address?);

  pub let CollectionStoragePath: StoragePath;
  pub let CollectionPublicPath: PublicPath;
  pub let MinterStoragePath: StoragePath;
  pub let SaleCollectionStoragePath: StoragePath;
  pub let SaleCollectionPublicPath: PublicPath;

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver
  {
    pub let id: UInt64;
    pub let name: String;
    pub let description: String;
    pub let thumbnail: String;
    access(self) let royalties: [MetadataViews.Royalty];
    access(self) let metadata: {String: AnyStruct};

    init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata: {String: AnyStruct})
    {
      self.id = id;
      self.name = name;
      self.description = description;
      self.thumbnail = thumbnail;
      self.royalties = royalties;
      self.metadata = metadata;
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Editions>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Traits>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? 
    {
      switch view 
      {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: self.name,
            description: self.description,
            thumbnail: MetadataViews.HTTPFile(url: self.thumbnail)
          )

        case Type<MetadataViews.Editions>():
          let editionInfo = MetadataViews.Edition(name: "NFT Contract Edition", number: self.id, max: nil);
          let editionList: [MetadataViews.Edition] = [editionInfo];
          return MetadataViews.Editions(editionList);

        case Type<MetadataViews.Serial>():
          return MetadataViews.Serial(self.id);

        case Type<MetadataViews.Royalties>():
          return MetadataViews.Royalties(self.royalties);

        case Type<MetadataViews.ExternalURL>():
          return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()));

        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: NFTContract.CollectionStoragePath,
            publicPath: NFTContract.CollectionPublicPath,
            providerPath: /private/nftContractCollection,
            publicCollection: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic}>(),
            publicLinkedType: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
              return <-NFTContract.createEmptyCollection();
            })
          )

        case Type<MetadataViews.NFTCollectionDisplay>():
          let media = MetadataViews.Media(
            file: MetadataViews.HTTPFile(
              url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
            ),
            mediaType: "image/svg+xml"
          )
          return MetadataViews.NFTCollectionDisplay(
            name: "The Example Collection",
            description: "This collection is used as an example to help you develop your next Flow NFT.",
            externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
            squareImage: media,
            bannerImage: media,
            socials: {
              "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
            }
          )

        case Type<MetadataViews.Traits>():
          let excludedTraits = ["mintedTime", "foo"];
          let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits);
          let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil);
          traitsView.addTrait(mintedTimeTrait);
          let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common");
          let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity);
          traitsView.addTrait(fooTrait);
          return traitsView;
      }
      return nil;
    }
  }

  pub resource interface NFTContractCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64];
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT;
    pub fun borrowNFTContract(id: UInt64): &NFTContract.NFT? {
      post {
        (result == nil) || (result?.id == id): "Cannot borrow NFTContract reference: the ID of the returned reference is incorrect";
      }
    }
  }

  pub resource Collection: NFTContractCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection 
  {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT};

    init () 
    {
      self.ownedNFTs <- {};
    }

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT 
    {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT");
      emit Withdraw(id: token.id, from: self.owner?.address);
      return <-token;
    }

    pub fun deposit(token: @NonFungibleToken.NFT) 
    {
      let token <- token as! @NFTContract.NFT;
      let id: UInt64 = token.id;
      let oldToken <- self.ownedNFTs[id] <- token;
      emit Deposit(id: id, to: self.owner?.address);
      destroy oldToken;
    }

    pub fun getIDs(): [UInt64] 
    {
      return self.ownedNFTs.keys;
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT 
    {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!;
    }

    pub fun borrowNFTContract(id: UInt64): &NFTContract.NFT? 
    {
      if self.ownedNFTs[id] != nil
      {
        let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!;
        return ref as! &NFTContract.NFT;
      }

      return nil;
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} 
    {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!;
      let nftContract = nft as! &NFTContract.NFT;
      return nftContract;
    }

    destroy() 
    {
      destroy self.ownedNFTs;
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection 
  {
    return <- create Collection()
  }

  pub resource NFTMinter 
  {
    pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty]) 
    {
      let metadata: {String: AnyStruct} = {};
      let currentBlock = getCurrentBlock();
      metadata["mintedBlock"] = currentBlock.height;
      metadata["mintedTime"] = currentBlock.timestamp;
      metadata["minter"] = recipient.owner!.address;

      metadata["foo"] = "bar";

      var newNFT <- create NFT(
        id: NFTContract.totalSupply,
        name: name,
        description: description,
        thumbnail: thumbnail,
        royalties: royalties,
        metadata: metadata,
      )

      recipient.deposit(token: <-newNFT);
      NFTContract.totalSupply = NFTContract.totalSupply + 1;
    }
  }

  pub fun resolveView(_ view: Type): AnyStruct? {
    switch view {
      case Type<MetadataViews.NFTCollectionData>():
        return MetadataViews.NFTCollectionData(
            storagePath: NFTContract.CollectionStoragePath,
            publicPath: NFTContract.CollectionPublicPath,
            providerPath: /private/exampleNFTCollection,
            publicCollection: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic}>(),
            publicLinkedType: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&NFTContract.Collection{NFTContract.NFTContractCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
              return <-NFTContract.createEmptyCollection()
            })
        )

      case Type<MetadataViews.NFTCollectionDisplay>():
        let media = MetadataViews.Media(
          file: MetadataViews.HTTPFile(
            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
          ),
          mediaType: "image/svg+xml"
        )

        return MetadataViews.NFTCollectionDisplay(
          name: "The Example Collection",
          description: "This collection is used as an example to help you develop your next Flow NFT.",
          externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
          squareImage: media,
          bannerImage: media,
          socials: {
            "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
          }
        )
    }
    return nil
  }

  init()
  {
    self.totalSupply = 0;
    self.CollectionStoragePath = /storage/NFTCollection;
    self.CollectionPublicPath = /public/NFTCollection;
    self.MinterStoragePath = /storage/NFTMinter;
    self.SaleCollectionStoragePath = /storage/SaleCollection;
    self.SaleCollectionPublicPath = /public/SaleCollection;

    let collection <- create Collection();
    self.account.save(<-collection, to: self.CollectionStoragePath);

    self.account.link<&NFTContract.Collection{NonFungibleToken.CollectionPublic, NFTContract.NFTContractCollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )

    let minter <- create NFTMinter();
    self.account.save(<-minter, to: self.MinterStoragePath);

    emit ContractInitialized();
  }
}