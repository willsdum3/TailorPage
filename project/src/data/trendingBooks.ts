export interface TrendingBook {
  id: string;
  title: string;
  author: string;
  genre: string;
  description: string;
  amazonLink: string;
  rank: number;
  price: string;
  rating: number;
  reviewCount: number;
  coverImage?: string;
}

export const trendingBooks: TrendingBook[] = [
  {
    id: 'fourth-wing',
    title: 'Fourth Wing',
    author: 'Rebecca Yarros',
    genre: 'Fantasy Romance',
    description: 'Enter the brutal and elite world of a war college for dragon riders.',
    amazonLink: 'https://amzn.eu/d/0GWJJxz',
    rank: 1,
    price: '£9.99',
    rating: 4.6,
    reviewCount: 89234,
    coverImage: 'https://m.media-amazon.com/images/I/81cquiyLW8L._SY466_.jpg'
  },
  {
    id: 'iron-flame',
    title: 'Iron Flame',
    author: 'Rebecca Yarros',
    genre: 'Fantasy Romance',
    description: 'The highly anticipated sequel to Fourth Wing.',
    amazonLink: 'https://amzn.eu/d/9Tz3OSX',
    rank: 2,
    price: '£10.99',
    rating: 4.5,
    reviewCount: 67891,
    coverImage: 'https://m.media-amazon.com/images/I/71Zb-D8NaGL._SY466_.jpg'
  },
  {
    id: 'atomic-habits',
    title: 'Atomic Habits',
    author: 'James Clear',
    genre: 'Self-Help',
    description: 'An Easy & Proven Way to Build Good Habits & Break Bad Ones.',
    amazonLink: 'https://www.amazon.co.uk/dp/1847941834',
    rank: 3,
    price: '£10.99',
    rating: 4.7,
    reviewCount: 156789,
    coverImage: 'https://m.media-amazon.com/images/I/81wgcld4wxL._SY466_.jpg'
  },
  {
    id: 'it-ends-with-us',
    title: 'It Ends with Us',
    author: 'Colleen Hoover',
    genre: 'Contemporary Romance',
    description: 'A powerful story about love, courage, and the strength to break cycles.',
    amazonLink: 'https://www.amazon.co.uk/dp/1471156265',
    rank: 4,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 234567,
    coverImage: 'https://m.media-amazon.com/images/I/81wgcld4wxL._SY466_.jpg'
  },
  {
    id: 'it-starts-with-us',
    title: 'It Starts with Us',
    author: 'Colleen Hoover',
    genre: 'Contemporary Romance',
    description: 'The sequel to the bestselling It Ends with Us.',
    amazonLink: 'https://amzn.eu/d/bLm3fls',
    rank: 5,
    price: '£7.99',
    rating: 4.3,
    reviewCount: 178923,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  },
  {
    id: 'verity',
    title: 'Verity',
    author: 'Colleen Hoover',
    genre: 'Thriller',
    description: 'A psychological thriller that will keep you guessing until the very end.',
    amazonLink: 'https://amzn.eu/d/gbSNGgf',
    rank: 6,
    price: '£7.99',
    rating: 4.5,
    reviewCount: 145678,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  },
  {
    id: 'the-housemaid',
    title: 'The Housemaid',
    author: 'Freida McFadden',
    genre: 'Thriller',
    description: 'A psychological thriller about a housemaid with a dark secret.',
    amazonLink: 'https://www.amazon.co.uk/dp/1538742578',
    rank: 7,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 98765,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  },
  {
    id: 'lessons-in-chemistry',
    title: 'Lessons in Chemistry',
    author: 'Bonnie Garmus',
    genre: 'Historical Fiction',
    description: 'A novel about a female scientist in the 1960s who becomes a cooking show host.',
    amazonLink: 'https://amzn.eu/d/6NCOTQ1',
    rank: 8,
    price: '£7.99',
    rating: 4.6,
    reviewCount: 123456,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  },
  {
    id: 'the-silent-patient',
    title: 'The Silent Patient',
    author: 'Alex Michaelides',
    genre: 'Thriller',
    description: 'A psychological thriller about a woman who shoots her husband and then never speaks again.',
    amazonLink: 'https://www.amazon.co.uk/dp/1409181634',
    rank: 9,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 167890,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  },
  {
    id: 'the-guest-list',
    title: 'The Guest List',
    author: 'Lucy Foley',
    genre: 'Thriller',
    description: 'A wedding celebration turns deadly in this atmospheric thriller.',
    amazonLink: 'https://amzn.eu/d/2pzng2U',
    rank: 10,
    price: '£7.99',
    rating: 4.3,
    reviewCount: 98765,
    coverImage: 'https://m.media-amazon.com/images/I/81cJTmFpG-L._SY466_.jpg'
  }
];