export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

export const LISTING_TYPES = {
  NONE: 0,
  FIXED_PRICE: 1,
  AUCTION: 2,
};

export type Token = {
  to: string;
  tokenId: number;
  amount: number;
  metadataUri: string;
};

export type Tokens = {
  to: string;
  tokenIds: Array<number>;
  amounts: Array<number>;
  metadataUris: Array<string>;
};

export enum ListingType {
  NONE,
  FIXED_PRICE,
  AUCTION,
}

export type List = {
  listingType: ListingType;
  nftContract: string;
  listedQuantity: string;
  tokenId: string;
  price: string;
  startTime: string;
  endTime: string;
};

