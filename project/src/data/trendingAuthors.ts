export interface TrendingAuthor {
  id: string;
  name: string;
  rank: number;
  genre: string;
  bio: string;
  imageUrl: string;
  popularBooks: string[];
  totalBooks: number;
  followers: number;
  recentActivity: string;
  amazonAuthorLink: string;
  socialMedia?: {
    twitter?: string;
    instagram?: string;
    website?: string;
  };
  location: string; // Added location field
}

export const trendingAuthors: TrendingAuthor[] = [
  {
    id: 'taylor-jenkins-reid',
    name: 'Taylor Jenkins Reid',
    rank: 1,
    genre: 'Contemporary Fiction',
    bio: 'New York Times bestselling author known for her captivating novels about complex characters and relationships. Her works often explore themes of fame, love, and family dynamics.',
    imageUrl: '/taylorjenkinsreid.jpg',
    popularBooks: ['The Seven Husbands of Evelyn Hugo', 'Daisy Jones & The Six', 'Malibu Rising'],
    totalBooks: 8,
    followers: 892000,
    recentActivity: 'New novel "Carrie Soto Is Back" climbing bestseller lists',
    amazonAuthorLink: 'https://www.amazon.co.uk/Taylor-Jenkins-Reid/e/B00J1H0C0C',
    socialMedia: {
      twitter: '@tjenkinsreid',
      instagram: '@tjenkinsreid',
      website: 'https://taylorjenkinsreid.com'
    },
    location: 'Los Angeles, USA'
  },
  {
    id: 'rebecca-yarros',
    name: 'Rebecca Yarros',
    rank: 2,
    genre: 'Fantasy Romance',
    bio: 'Military spouse and bestselling author who has taken the fantasy romance world by storm. Known for her emotionally charged stories and strong character development.',
    imageUrl: '/rebeccayarros.jpg',
    popularBooks: ['Fourth Wing', 'Iron Flame', 'In the Likely Event'],
    totalBooks: 15,
    followers: 756000,
    recentActivity: 'Fourth Wing series dominating TikTok and bestseller charts',
    amazonAuthorLink: 'https://www.amazon.co.uk/Rebecca-Yarros/e/B00J8XUKT8',
    socialMedia: {
      instagram: '@rebeccayarros'
    },
    location: 'London, UK'
  },
  {
    id: 've-schwab',
    name: 'V.E. Schwab',
    rank: 3,
    genre: 'Fantasy',
    bio: 'Victoria "V.E." Schwab is a bestselling author known for her dark fantasy novels and compelling magic systems. She writes for both adult and young adult audiences.',
    imageUrl: '/veschwab.jpg',
    popularBooks: ['The Invisible Life of Addie LaRue', 'Vicious', 'A Darker Shade of Magic'],
    totalBooks: 20,
    followers: 634000,
    recentActivity: 'New Shades of Magic series installment announced',
    amazonAuthorLink: 'https://www.amazon.co.uk/V-E-Schwab/e/B00JVJFRUO',
    socialMedia: {
      twitter: '@VESchwab',
      instagram: '@veschwab'
    },
    location: 'New York, USA'
  },
  {
    id: 'stephen-king',
    name: 'Stephen King',
    rank: 4,
    genre: 'Horror',
    bio: 'The undisputed master of horror fiction with over 60 novels and 200 short stories. His works have sold more than 350 million copies worldwide.',
    imageUrl: '/stephenking.jpg',
    popularBooks: ['It', 'The Shining', 'Pet Sematary'],
    totalBooks: 65,
    followers: 1200000,
    recentActivity: 'Latest novel "Holly" receiving critical acclaim',
    amazonAuthorLink: 'https://www.amazon.co.uk/Stephen-King/e/B000AQ0842',
    socialMedia: {
      twitter: '@StephenKing'
    },
    location: 'Portland, USA'
  },
  {
    id: 'james-patterson',
    name: 'James Patterson',
    rank: 5,
    genre: 'Thriller',
    bio: 'One of the world\'s bestselling authors, known for his Alex Cross and Women\'s Murder Club series. His books have sold over 400 million copies worldwide.',
    imageUrl: '/jamespatterson.jpg',
    popularBooks: ['Along Came a Spider', '1st to Die', 'Kiss the Girls'],
    totalBooks: 200,
    followers: 987000,
    recentActivity: 'New Alex Cross thriller "Cross Down" released',
    amazonAuthorLink: 'https://www.amazon.co.uk/James-Patterson/e/B000APXGDM',
    socialMedia: {
      twitter: '@McGillPatterson',
      instagram: '@jamespattersonbooks'
    },
    location: 'New York, USA'
  },
  {
    id: 'freida-mcfadden',
    name: 'Freida McFadden',
    rank: 6,
    genre: 'Psychological Thriller',
    bio: 'Practicing physician turned bestselling thriller author. Her psychological thrillers are known for their shocking twists and medical authenticity.',
    imageUrl: '/friedamcfadden.jpg',
    popularBooks: ['The Housemaid', 'The Housemaid\'s Secret', 'Never Lie'],
    totalBooks: 12,
    followers: 445000,
    recentActivity: 'The Housemaid series viral on social media',
    amazonAuthorLink: 'https://www.amazon.co.uk/Freida-McFadden/e/B07JVQZB6X',
    socialMedia: {
      twitter: '@freida_mcfadden',
      instagram: '@fmcfaddenauthor'
    },
    location: 'Los Angeles, USA'
  },
  {
    id: 'sarah-j-maas',
    name: 'Sarah J. Maas',
    rank: 7,
    genre: 'Fantasy Romance',
    bio: 'New York Times bestselling author of the Throne of Glass and A Court of Thorns and Roses series. Known for her epic fantasy worlds and romantic storylines.',
    imageUrl: '/sarahjmaas.png',
    popularBooks: ['A Court of Thorns and Roses', 'Throne of Glass', 'House of Earth and Blood'],
    totalBooks: 16,
    followers: 823000,
    recentActivity: 'Crescent City series gaining massive following',
    amazonAuthorLink: 'https://www.amazon.co.uk/Sarah-J-Maas/e/B00J06IQJW',
    socialMedia: {
      instagram: '@sarahjmaas'
    },
    location: 'New York, USA'
  },
  {
    id: 'ali-hazelwood',
    name: 'Ali Hazelwood',
    rank: 8,
    genre: 'Contemporary Romance',
    bio: 'Former academic turned romance novelist, known for her STEM-focused contemporary romances featuring strong, intelligent heroines in academic settings.',
    imageUrl: '/alihazelwood.jpg',
    popularBooks: ['The Love Hypothesis', 'Beach Read', 'The Spanish Love Deception'],
    totalBooks: 6,
    followers: 567000,
    recentActivity: 'New space-themed romance series announced',
    amazonAuthorLink: 'https://www.amazon.co.uk/Ali-Hazelwood/e/B08XQJQZQX',
    socialMedia: {
      website: 'https://alihazelwood.com'
    },
    location: 'Los Angeles, USA'
  },
  {
    id: 'alex-michaelides',
    name: 'Alex Michaelides',
    rank: 9,
    genre: 'Psychological Thriller',
    bio: 'British-Cypriot author and screenwriter known for his psychological thrillers with unreliable narrators and shocking plot twists.',
    imageUrl: '/alexmichaelides.jpg',
    popularBooks: ['The Silent Patient', 'The Maidens', 'The Fury'],
    totalBooks: 4,
    followers: 389000,
    recentActivity: 'The Silent Patient continues to dominate thriller charts',
    amazonAuthorLink: 'https://www.amazon.co.uk/Alex-Michaelides/e/B07MDHQZQX',
    // No verified social media accounts found
    location: 'London, UK'
  },
  {
    id: 'rf-kuang',
    name: 'R.F. Kuang',
    rank: 10,
    genre: 'Dark Fantasy',
    bio: 'Award-winning author known for her dark fantasy novels that blend historical elements with magic. Her works tackle complex themes of war, power, and identity.',
    imageUrl: '/rfkuang.jpg',
    popularBooks: ['The Poppy War', 'Babel', 'The Dragon Republic'],
    totalBooks: 5,
    followers: 234000,
    recentActivity: 'Babel winning multiple literary awards',
    amazonAuthorLink: 'https://www.amazon.co.uk/R-F-Kuang/e/B07B2XQZQX',
    // No direct social media links found
    location: 'New York, USA'
  }
];