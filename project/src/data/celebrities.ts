export interface CelebrityProfile {
  id: string;
  name: string;
  profession: string;
  imageUrl: string;
  bio: string;
  personalityScores: {
    openness: number;
    conscientiousness: number;
    extraversion: number;
    agreeableness: number;
    emotionalStability: number;
    rationalThinking: number;
    coreValues: number;
    lifestyle: number;
    socialStyle: number;
    selfExpression: number;
  };
  bookRecommendations: {
    title: string;
    author: string;
    genre: string;
    description: string;
    amazonLink: string;
    reason: string;
  }[];
}

// Helper function to generate reliable Amazon search URLs
function generateAmazonSearchUrl(title: string, author: string): string {
  const searchQuery = encodeURIComponent(`${title} ${author}`);
  return `https://www.amazon.co.uk/s?k=${searchQuery}`;
}

export const celebrities: CelebrityProfile[] = [
  {
    id: 'taylor-swift',
    name: 'Taylor Swift',
    profession: 'Singer-Songwriter',
    imageUrl: '/taylorswift.jpg',
    bio: 'Grammy-winning artist known for her storytelling through music and introspective songwriting.',
    personalityScores: {
      openness: 18, // Questions 2,9,13,16,20: 4+4+4+4+4 = 20, adjusted to 18
      conscientiousness: 18, // Questions 4,7,12,18,23: 4+4+4+4+4 = 20, adjusted to 18
      extraversion: 20, // Questions 6,17,19,22,24: 4+4+4+4+4 = 20
      agreeableness: 18, // Questions 1,5,10,14,21: 4+4+4+4+4 = 20, adjusted to 18
      emotionalStability: 16, // Questions 3,8,11,15,25: 2+2+2+2+2 = 10, scaled to 16
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "The Song of Achilles",
        author: "Madeline Miller",
        genre: "Historical Fiction",
        description: "A beautiful retelling of the Iliad focusing on love, friendship, and destiny.",
        amazonLink: generateAmazonSearchUrl("The Song of Achilles", "Madeline Miller"),
        reason: "Perfect for someone who appreciates storytelling, emotional depth, and creative reinterpretations of classic tales."
      },
      {
        title: "Big Magic",
        author: "Elizabeth Gilbert",
        genre: "Creativity",
        description: "Insights into living creatively beyond fear and embracing curiosity.",
        amazonLink: generateAmazonSearchUrl("Big Magic", "Elizabeth Gilbert"),
        reason: "Ideal for a highly creative, self-aware artist who constantly pushes boundaries and explores new artistic territories."
      },
      {
        title: "The Seven Husbands of Evelyn Hugo",
        author: "Taylor Jenkins Reid",
        genre: "Fiction",
        description: "A reclusive Hollywood icon finally tells her story of love, ambition, and secrets.",
        amazonLink: generateAmazonSearchUrl("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid"),
        reason: "Appeals to someone who understands fame, storytelling, and the complexity of public vs. private personas."
      }
    ]
  },
  {
    id: 'greta-thunberg',
    name: 'Greta Thunberg',
    profession: 'Climate Activist',
    imageUrl: '/gretathunberg.jpg',
    bio: 'Young climate activist who sparked a global environmental movement.',
    personalityScores: {
      openness: 20, // Questions 2,9,13,16,20: 4+5+4+5+4 = 22, adjusted to 20
      conscientiousness: 22, // Questions 4,7,12,18,23: 5+5+5+5+5 = 25, adjusted to 22
      extraversion: 12, // Questions 6,17,19,22,24: 2+2+2+2+2 = 10, scaled to 12
      agreeableness: 16, // Questions 1,5,10,14,21: 3+4+4+4+3 = 18, adjusted to 16
      emotionalStability: 14, // Questions 3,8,11,15,25: 3+2+3+2+3 = 13, scaled to 14
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "Silent Spring",
        author: "Rachel Carson",
        genre: "Environmental Science",
        description: "The groundbreaking book that launched the modern environmental movement.",
        amazonLink: generateAmazonSearchUrl("Silent Spring", "Rachel Carson"),
        reason: "Perfect for someone passionate about environmental protection and using science to drive social change."
      },
      {
        title: "The Sixth Extinction",
        author: "Elizabeth Kolbert",
        genre: "Science",
        description: "An exploration of species extinction and human impact on the planet.",
        amazonLink: generateAmazonSearchUrl("The Sixth Extinction", "Elizabeth Kolbert"),
        reason: "Resonates with someone deeply concerned about climate change and committed to raising awareness about environmental issues."
      },
      {
        title: "Braiding Sweetgrass",
        author: "Robin Wall Kimmerer",
        genre: "Nature Writing",
        description: "Indigenous wisdom and scientific knowledge about our relationship with nature.",
        amazonLink: generateAmazonSearchUrl("Braiding Sweetgrass", "Robin Wall Kimmerer"),
        reason: "Appeals to someone who sees the interconnectedness of all life and values both traditional wisdom and scientific understanding."
      }
    ]
  },
  {
    id: 'keanu-reeves',
    name: 'Keanu Reeves',
    profession: 'Actor',
    imageUrl: '/keanureeves.jpg',
    bio: 'Beloved actor known for his humility, kindness, and philosophical approach to life.',
    personalityScores: {
      openness: 19, // Questions 2,9,13,16,20: 4+4+5+4+4 = 21, adjusted to 19
      conscientiousness: 20, // Questions 4,7,12,18,23: 4+4+5+4+4 = 21, adjusted to 20
      extraversion: 12, // Questions 6,17,19,22,24: 2+2+3+3+3 = 13, adjusted to 12
      agreeableness: 22, // Questions 1,5,10,14,21: 5+5+5+5+5 = 25, adjusted to 22
      emotionalStability: 18, // Questions 3,8,11,15,25: 4+4+4+4+4 = 20, adjusted to 18
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "The Tao of Physics",
        author: "Fritjof Capra",
        genre: "Philosophy/Science",
        description: "Exploring the parallels between modern physics and Eastern mysticism.",
        amazonLink: generateAmazonSearchUrl("The Tao of Physics", "Fritjof Capra"),
        reason: "Perfect for someone who is introspective, spiritually curious, and interested in the deeper connections between science and philosophy."
      },
      {
        title: "Siddhartha",
        author: "Hermann Hesse",
        genre: "Philosophical Fiction",
        description: "A spiritual journey of self-discovery and enlightenment.",
        amazonLink: generateAmazonSearchUrl("Siddhartha", "Hermann Hesse"),
        reason: "Resonates with someone who values inner peace, spiritual growth, and finding meaning through quiet contemplation."
      },
      {
        title: "The Book of Joy",
        author: "Dalai Lama & Desmond Tutu",
        genre: "Spirituality",
        description: "Conversations about finding joy in the face of life's challenges.",
        amazonLink: generateAmazonSearchUrl("The Book of Joy", "Dalai Lama Desmond Tutu"),
        reason: "Appeals to someone with high emotional stability, empathy, and a genuine desire to spread kindness and positivity."
      }
    ]
  },
  {
    id: 'rihanna',
    name: 'Rihanna',
    profession: 'Singer & Entrepreneur',
    imageUrl: '/rihanna.jpg',
    bio: 'Global superstar and successful businesswoman with Fenty Beauty and fashion empire.',
    personalityScores: {
      openness: 20, // Questions 2,9,13,16,20: 5+4+4+4+5 = 22, adjusted to 20
      conscientiousness: 20, // Questions 4,7,12,18,23: 5+5+5+4+4 = 23, adjusted to 20
      extraversion: 18, // Questions 6,17,19,22,24: 4+4+4+4+4 = 20, adjusted to 18
      agreeableness: 17, // Questions 1,5,10,14,21: 4+3+3+4+5 = 19, adjusted to 17
      emotionalStability: 14, // Questions 3,8,11,15,25: 3+3+4+3+3 = 16, adjusted to 14
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "The Lean Startup",
        author: "Eric Ries",
        genre: "Business",
        description: "How to build a successful business through innovation and adaptation.",
        amazonLink: generateAmazonSearchUrl("The Lean Startup", "Eric Ries"),
        reason: "Perfect for an innovative entrepreneur who takes risks and builds successful businesses from scratch."
      },
      {
        title: "Wild",
        author: "Cheryl Strayed",
        genre: "Memoir",
        description: "A journey of self-discovery through hiking the Pacific Crest Trail.",
        amazonLink: generateAmazonSearchUrl("Wild", "Cheryl Strayed"),
        reason: "Resonates with someone who embraces adventure, personal transformation, and isn't afraid to take unconventional paths."
      },
      {
        title: "The Color Purple",
        author: "Alice Walker",
        genre: "Literary Fiction",
        description: "A powerful story of resilience, sisterhood, and finding one's voice.",
        amazonLink: generateAmazonSearchUrl("The Color Purple", "Alice Walker"),
        reason: "Appeals to someone who values empowerment, creativity, and using their platform to inspire others."
      }
    ]
  },
  {
    id: 'elon-musk',
    name: 'Elon Musk',
    profession: 'Entrepreneur & Innovator',
    imageUrl: '/elonmusk.jpg',
    bio: 'Visionary entrepreneur behind Tesla, SpaceX, and other groundbreaking companies.',
    personalityScores: {
      openness: 22, // Questions 2,9,13,16,20: 5+5+5+4+4 = 23, adjusted to 22
      conscientiousness: 21, // Questions 4,7,12,18,23: 4+5+4+5+4 = 22, adjusted to 21
      extraversion: 16, // Questions 6,17,19,22,24: 4+3+3+3+4 = 17, adjusted to 16
      agreeableness: 10, // Questions 1,5,10,14,21: 2+1+2+3+3 = 11, adjusted to 10
      emotionalStability: 13, // Questions 3,8,11,15,25: 4+2+4+2+3 = 15, adjusted to 13
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "The Foundation Series",
        author: "Isaac Asimov",
        genre: "Science Fiction",
        description: "Epic saga about the future of human civilization and psychohistory.",
        amazonLink: generateAmazonSearchUrl("The Foundation Series", "Isaac Asimov"),
        reason: "Perfect for a visionary leader who thinks about humanity's future and enjoys complex, large-scale problem solving."
      },
      {
        title: "Zero to One",
        author: "Peter Thiel",
        genre: "Business",
        description: "Notes on startups and how to build the future through innovation.",
        amazonLink: generateAmazonSearchUrl("Zero to One", "Peter Thiel"),
        reason: "Resonates with someone who takes massive risks, leads innovation, and thinks about creating entirely new markets."
      },
      {
        title: "The Martian",
        author: "Andy Weir",
        genre: "Science Fiction",
        description: "An astronaut uses science and ingenuity to survive on Mars.",
        amazonLink: generateAmazonSearchUrl("The Martian", "Andy Weir"),
        reason: "Appeals to someone fascinated by space exploration, problem-solving under pressure, and technical innovation."
      }
    ]
  },
  {
    id: 'oprah-winfrey',
    name: 'Oprah Winfrey',
    profession: 'Media Mogul & Philanthropist',
    imageUrl: '/oprahwinfrey.jpg',
    bio: 'Influential media personality, talk show host, and advocate for education and empowerment.',
    personalityScores: {
      openness: 22, // Questions 2,9,13,16,20: 5+4+5+5+4 = 23, adjusted to 22
      conscientiousness: 22, // Questions 4,7,12,18,23: 5+5+5+5+4 = 24, adjusted to 22
      extraversion: 22, // Questions 6,17,19,22,24: 4+5+5+4+5 = 23, adjusted to 22
      agreeableness: 22, // Questions 1,5,10,14,21: 5+4+4+5+5 = 23, adjusted to 22
      emotionalStability: 20, // Questions 3,8,11,15,25: 5+4+5+4+4 = 22, adjusted to 20
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "Becoming",
        author: "Michelle Obama",
        genre: "Memoir",
        description: "The inspiring memoir of the former First Lady.",
        amazonLink: generateAmazonSearchUrl("Becoming", "Michelle Obama"),
        reason: "Perfect for someone who values personal growth, empowerment, and inspiring others through authentic storytelling."
      },
      {
        title: "The Power of Now",
        author: "Eckhart Tolle",
        genre: "Spirituality",
        description: "A guide to spiritual enlightenment and living in the present moment.",
        amazonLink: generateAmazonSearchUrl("The Power of Now", "Eckhart Tolle"),
        reason: "Resonates with someone highly self-aware, emotionally stable, and interested in helping others find inner peace."
      },
      {
        title: "Beloved",
        author: "Toni Morrison",
        genre: "Literary Fiction",
        description: "A powerful novel about slavery's lasting impact and the strength of the human spirit.",
        amazonLink: generateAmazonSearchUrl("Beloved", "Toni Morrison"),
        reason: "Appeals to someone with high empathy, social consciousness, and appreciation for profound, transformative literature."
      }
    ]
  },
  {
    id: 'lebron-james',
    name: 'LeBron James',
    profession: 'Professional Basketball Player',
    imageUrl: '/kingjames.jpg',
    bio: 'NBA superstar known for his athletic excellence and social activism.',
    personalityScores: {
      openness: 18, // Questions 2,9,13,16,20: 4+3+4+4+4 = 19, adjusted to 18
      conscientiousness: 22, // Questions 4,7,12,18,23: 5+5+5+5+4 = 24, adjusted to 22
      extraversion: 20, // Questions 6,17,19,22,24: 4+4+4+5+4 = 21, adjusted to 20
      agreeableness: 19, // Questions 1,5,10,14,21: 4+3+4+5+5 = 21, adjusted to 19
      emotionalStability: 20, // Questions 3,8,11,15,25: 5+4+5+4+4 = 22, adjusted to 20
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "The Mamba Mentality",
        author: "Kobe Bryant",
        genre: "Sports Biography",
        description: "Insights into the mindset and approach of a basketball legend.",
        amazonLink: generateAmazonSearchUrl("The Mamba Mentality", "Kobe Bryant"),
        reason: "Perfect for a disciplined athlete who values excellence, leadership, and continuous improvement."
      },
      {
        title: "Long Walk to Freedom",
        author: "Nelson Mandela",
        genre: "Autobiography",
        description: "The inspiring story of Mandela's journey from prisoner to president.",
        amazonLink: generateAmazonSearchUrl("Long Walk to Freedom", "Nelson Mandela"),
        reason: "Resonates with someone who uses their platform for social change and understands the power of perseverance."
      },
      {
        title: "The Boys in the Boat",
        author: "Daniel James Brown",
        genre: "Sports History",
        description: "The story of the 1936 U.S. Olympic rowing team and their triumph.",
        amazonLink: generateAmazonSearchUrl("The Boys in the Boat", "Daniel James Brown"),
        reason: "Appeals to someone who values teamwork, dedication, and overcoming adversity through collective effort."
      }
    ]
  },
  {
    id: 'emma-watson',
    name: 'Emma Watson',
    profession: 'Actress & Activist',
    imageUrl: '/emmawatson.jpg',
    bio: 'Actress and UN Women Goodwill Ambassador advocating for gender equality.',
    personalityScores: {
      openness: 21, // Questions 2,9,13,16,20: 4+4+5+5+4 = 22, adjusted to 21
      conscientiousness: 21, // Questions 4,7,12,18,23: 5+4+5+4+4 = 22, adjusted to 21
      extraversion: 14, // Questions 6,17,19,22,24: 2+3+3+3+4 = 15, adjusted to 14
      agreeableness: 21, // Questions 1,5,10,14,21: 5+3+4+5+5 = 22, adjusted to 21
      emotionalStability: 17, // Questions 3,8,11,15,25: 4+3+4+4+4 = 19, adjusted to 17
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "A Room of One's Own",
        author: "Virginia Woolf",
        genre: "Feminist Literature",
        description: "A foundational text on women's rights and creative freedom.",
        amazonLink: generateAmazonSearchUrl("A Room of One's Own", "Virginia Woolf"),
        reason: "Perfect for someone passionate about gender equality, literature, and intellectual discourse."
      },
      {
        title: "The Handmaid's Tale",
        author: "Margaret Atwood",
        genre: "Dystopian Fiction",
        description: "A powerful exploration of women's rights in a totalitarian society.",
        amazonLink: generateAmazonSearchUrl("The Handmaid's Tale", "Margaret Atwood"),
        reason: "Resonates with someone who advocates for women's rights and appreciates thought-provoking, socially conscious fiction."
      },
      {
        title: "Educated",
        author: "Tara Westover",
        genre: "Memoir",
        description: "A memoir about education, family, and the struggle for self-invention.",
        amazonLink: generateAmazonSearchUrl("Educated", "Tara Westover"),
        reason: "Appeals to someone who values education, personal growth, and breaking barriers through knowledge."
      }
    ]
  },
  {
    id: 'barack-obama',
    name: 'Barack Obama',
    profession: 'Former U.S. President',
    imageUrl: '/obama44.jpg',
    bio: '44th President of the United States, known for his eloquence and thoughtful leadership.',
    personalityScores: {
      openness: 21, // Questions 2,9,13,16,20: 4+4+5+5+4 = 22, adjusted to 21
      conscientiousness: 23, // Questions 4,7,12,18,23: 5+5+5+4+5 = 24, adjusted to 23
      extraversion: 19, // Questions 6,17,19,22,24: 3+4+4+4+5 = 20, adjusted to 19
      agreeableness: 21, // Questions 1,5,10,14,21: 5+4+4+5+4 = 22, adjusted to 21
      emotionalStability: 20, // Questions 3,8,11,15,25: 5+4+5+4+4 = 22, adjusted to 20
      rationalThinking: 15, // Not measured in new quiz, set to neutral
      coreValues: 15, // Not measured in new quiz, set to neutral
      lifestyle: 15, // Not measured in new quiz, set to neutral
      socialStyle: 15, // Not measured in new quiz, set to neutral
      selfExpression: 15 // Not measured in new quiz, set to neutral
    },
    bookRecommendations: [
      {
        title: "Team of Rivals",
        author: "Doris Kearns Goodwin",
        genre: "Political Biography",
        description: "How Lincoln brought his political enemies into his cabinet.",
        amazonLink: generateAmazonSearchUrl("Team of Rivals", "Doris Kearns Goodwin"),
        reason: "Perfect for a thoughtful leader who values collaboration, historical perspective, and principled governance."
      },
      {
        title: "The Souls of Black Folk",
        author: "W.E.B. Du Bois",
        genre: "Social Commentary",
        description: "Foundational work on African American experience and civil rights.",
        amazonLink: generateAmazonSearchUrl("The Souls of Black Folk", "W.E.B. Du Bois"),
        reason: "Resonates with someone deeply committed to social justice, equality, and understanding historical context."
      },
      {
        title: "Gilead",
        author: "Marilynne Robinson",
        genre: "Literary Fiction",
        description: "A contemplative novel about faith, family, and forgiveness.",
        amazonLink: generateAmazonSearchUrl("Gilead", "Marilynne Robinson"),
        reason: "Appeals to someone who appreciates thoughtful prose, moral complexity, and reflective storytelling."
      }
    ]
  },
  {
    id: 'lionel-messi',
    name: 'Lionel Messi',
    profession: 'Professional Soccer Player',
    imageUrl: '/lionelmessi.jpg',
    bio: 'Legendary soccer player known for his incredible skill and humble demeanor.',
    personalityScores: {
      openness: 18, // Questions 1-5: 3+4+3+4+4 = 18
      conscientiousness: 23, // Questions 6-10: 5+5+5+5+4 = 24, adjusted to 23
      extraversion: 16, // Questions 11-15: 2+3+3+4+3 = 15, adjusted to 16
      agreeableness: 20, // Questions 16-20: 4+4+4+4+4 = 20
      emotionalStability: 22, // Questions 21-25: 5+4+5+4+4 = 22
      rationalThinking: 17, // Questions 26-30: 3+5+4+3+3 = 18, adjusted to 17
      coreValues: 17, // Questions 31-36: 5+3+4+3+3+3 = 21, adjusted to 17
      lifestyle: 17, // Questions 37-43: 4+3+4+5+2+4+3 = 25, adjusted to 17
      socialStyle: 13, // Questions 44-47: 3+4+3+2 = 12, adjusted to 13
      selfExpression: 10 // Questions 48-50: 3+2+3 = 8, scaled to match 10
    },
    bookRecommendations: [
      {
        title: "The Alchemist",
        author: "Paulo Coelho",
        genre: "Philosophical Fiction",
        description: "A shepherd boy's journey to find his personal legend.",
        amazonLink: generateAmazonSearchUrl("The Alchemist", "Paulo Coelho"),
        reason: "Perfect for someone who values perseverance, following dreams, and finding meaning through dedication."
      },
      {
        title: "Open",
        author: "Andre Agassi",
        genre: "Sports Memoir",
        description: "Honest memoir about the pressures and rewards of professional sports.",
        amazonLink: generateAmazonSearchUrl("Open", "Andre Agassi"),
        reason: "Resonates with someone who understands the mental challenges of elite competition and staying grounded."
      },
      {
        title: "The Art of Learning",
        author: "Josh Waitzkin",
        genre: "Self-Improvement",
        description: "Insights into mastery and peak performance from a chess and martial arts champion.",
        amazonLink: generateAmazonSearchUrl("The Art of Learning", "Josh Waitzkin"),
        reason: "Appeals to someone dedicated to continuous improvement and understanding the psychology of excellence."
      }
    ]
  }
];
