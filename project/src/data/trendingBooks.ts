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

}

// Helper function to generate reliable Amazon search URLs
function generateAmazonSearchUrl(title: string, author: string): string {
  const searchQuery = encodeURIComponent(`${title} ${author}`);
  return `https://www.amazon.co.uk/s?k=${searchQuery}`;
}

export const trendingBooks: TrendingBook[] = [
  {
    id: 'fourth-wing',
    title: 'Fourth Wing',
    author: 'Rebecca Yarros',
    genre: 'Fantasy Romance',
    description: 'Enter the brutal and elite world of a war college for dragon riders.',
    amazonLink: generateAmazonSearchUrl('Fourth Wing', 'Rebecca Yarros'),
    rank: 1,
    price: '£9.99',
    rating: 4.6,
    reviewCount: 89234
  },
  {
    id: 'iron-flame',
    title: 'Iron Flame',
    author: 'Rebecca Yarros',
    genre: 'Fantasy Romance',
    description: 'The highly anticipated sequel to Fourth Wing.',
    amazonLink: generateAmazonSearchUrl('Iron Flame', 'Rebecca Yarros'),
    rank: 2,
    price: '£10.99',
    rating: 4.5,
    reviewCount: 67891
  },
  {
    id: 'atomic-habits',
    title: 'Atomic Habits',
    author: 'James Clear',
    genre: 'Self-Help',
    description: 'An Easy & Proven Way to Build Good Habits & Break Bad Ones.',
    amazonLink: generateAmazonSearchUrl('Atomic Habits', 'James Clear'),
    rank: 3,
    price: '£10.99',
    rating: 4.7,
    reviewCount: 156789
  },
  {
    id: 'it-ends-with-us',
    title: 'It Ends with Us',
    author: 'Colleen Hoover',
    genre: 'Contemporary Romance',
    description: 'A powerful story about love, courage, and the strength to break cycles.',
    amazonLink: generateAmazonSearchUrl('It Ends with Us', 'Colleen Hoover'),
    rank: 4,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 234567
  },
  {
    id: 'it-starts-with-us',
    title: 'It Starts with Us',
    author: 'Colleen Hoover',
    genre: 'Contemporary Romance',
    description: 'The sequel to the bestselling It Ends with Us.',
    amazonLink: generateAmazonSearchUrl('It Starts with Us', 'Colleen Hoover'),
    rank: 5,
    price: '£7.99',
    rating: 4.3,
    reviewCount: 178923
  },
  {
    id: 'verity',
    title: 'Verity',
    author: 'Colleen Hoover',
    genre: 'Thriller',
    description: 'A psychological thriller that will keep you guessing until the very end.',
    amazonLink: generateAmazonSearchUrl('Verity', 'Colleen Hoover'),
    rank: 6,
    price: '£7.99',
    rating: 4.5,
    reviewCount: 145678
  },
  {
    id: 'the-housemaid',
    title: 'The Housemaid',
    author: 'Freida McFadden',
    genre: 'Thriller',
    description: 'A psychological thriller about a housemaid with a dark secret.',
    amazonLink: generateAmazonSearchUrl('The Housemaid', 'Freida McFadden'),
    rank: 7,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 98765
  },
  {
    id: 'lessons-in-chemistry',
    title: 'Lessons in Chemistry',
    author: 'Bonnie Garmus',
    genre: 'Historical Fiction',
    description: 'A novel about a female scientist in the 1960s who becomes a cooking show host.',
    amazonLink: generateAmazonSearchUrl('Lessons in Chemistry', 'Bonnie Garmus'),
    rank: 8,
    price: '£7.99',
    rating: 4.6,
    reviewCount: 123456
  },
  {
    id: 'the-silent-patient',
    title: 'The Silent Patient',
    author: 'Alex Michaelides',
    genre: 'Thriller',
    description: 'A psychological thriller about a woman who shoots her husband and then never speaks again.',
    amazonLink: generateAmazonSearchUrl('The Silent Patient', 'Alex Michaelides'),
    rank: 9,
    price: '£7.99',
    rating: 4.4,
    reviewCount: 167890
  },
  {
    id: 'the-guest-list',
    title: 'The Guest List',
    author: 'Lucy Foley',
    genre: 'Thriller',
    description: 'A wedding celebration turns deadly in this atmospheric thriller.',
    amazonLink: generateAmazonSearchUrl('The Guest List', 'Lucy Foley'),
    rank: 10,
    price: '£7.99',
    rating: 4.3,
    reviewCount: 98765
  }
];