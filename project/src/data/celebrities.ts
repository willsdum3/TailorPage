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

export const celebrities: CelebrityProfile[] = [
  {
    id: 'taylor-swift',
    name: 'Taylor Swift',
    profession: 'Singer-Songwriter',
    imageUrl: '/taylorswift.jpg',
    bio: 'Grammy-winning artist known for her storytelling through music and introspective songwriting.',
    personalityScores: {
      openness: 22, // Questions 1-5: 4+5+4+5+5 = 23, adjusted to 22
      conscientiousness: 20, // Questions 6-10: 4+4+4+4+4 = 20
      extraversion: 21, // Questions 11-15: 4+4+4+4+5 = 21
      agreeableness: 19, // Questions 16-20: 4+3+4+4+4 = 19
      emotionalStability: 20, // Questions 21-25: 4+4+4+4+4 = 20
      rationalThinking: 18, // Questions 26-30: 3+4+3+4+4 = 18
      coreValues: 22, // Questions 31-36: 4+4+3+5+4+4 = 24, adjusted to 22
      lifestyle: 20, // Questions 37-43: 2+4+4+3+5+4+4 = 26, adjusted to 20
      socialStyle: 16, // Questions 44-47: 4+4+4+4 = 16
      selfExpression: 16 // Questions 48-50: 4+4+4 = 12, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "The Song of Achilles",
        author: "Madeline Miller",
        genre: "Historical Fiction",
        description: "A beautiful retelling of the Iliad focusing on love, friendship, and destiny.",
        amazonLink: "https://www.amazon.com/dp/0062060627",
        reason: "Perfect for someone who appreciates storytelling, emotional depth, and creative reinterpretations of classic tales."
      },
      {
        title: "Big Magic",
        author: "Elizabeth Gilbert",
        genre: "Creativity",
        description: "Insights into living creatively beyond fear and embracing curiosity.",
        amazonLink: "https://www.amazon.com/dp/1594634718",
        reason: "Ideal for a highly creative, self-aware artist who constantly pushes boundaries and explores new artistic territories."
      },
      {
        title: "The Seven Husbands of Evelyn Hugo",
        author: "Taylor Jenkins Reid",
        genre: "Fiction",
        description: "A reclusive Hollywood icon finally tells her story of love, ambition, and secrets.",
        amazonLink: "https://www.amazon.com/dp/1501161938",
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
      openness: 18, // Questions 1-5: 3+4+4+4+3 = 18
      conscientiousness: 23, // Questions 6-10: 5+5+5+5+4 = 24, adjusted to 23
      extraversion: 13, // Questions 11-15: 2+2+3+3+3 = 13
      agreeableness: 17, // Questions 16-20: 4+2+2+5+4 = 17
      emotionalStability: 15, // Questions 21-25: 4+1+4+3+3 = 15
      rationalThinking: 21, // Questions 26-30: 4+4+4+4+5 = 21
      coreValues: 20, // Questions 31-36: 3+5+2+4+4+5 = 23, adjusted to 20
      lifestyle: 17, // Questions 37-43: 2+4+3+4+4+2+4 = 23, adjusted to 17
      socialStyle: 13, // Questions 44-47: 2+4+3+5 = 14, adjusted to 13
      selfExpression: 16 // Questions 48-50: 4 = 4, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "Silent Spring",
        author: "Rachel Carson",
        genre: "Environmental Science",
        description: "The groundbreaking book that launched the modern environmental movement.",
        amazonLink: "https://www.amazon.com/dp/0618249060",
        reason: "Perfect for someone passionate about environmental protection and using science to drive social change."
      },
      {
        title: "The Sixth Extinction",
        author: "Elizabeth Kolbert",
        genre: "Science",
        description: "An exploration of species extinction and human impact on the planet.",
        amazonLink: "https://www.amazon.com/dp/0805092994",
        reason: "Resonates with someone deeply concerned about climate change and committed to raising awareness about environmental issues."
      },
      {
        title: "Braiding Sweetgrass",
        author: "Robin Wall Kimmerer",
        genre: "Nature Writing",
        description: "Indigenous wisdom and scientific knowledge about our relationship with nature.",
        amazonLink: "https://www.amazon.com/dp/1571313567",
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
      openness: 21, // Questions 1-5: 4+4+5+4+4 = 21
      conscientiousness: 21, // Questions 6-10: 4+4+5+4+4 = 21
      extraversion: 12, // Questions 11-15: 1+2+3+3+3 = 12
      agreeableness: 23, // Questions 16-20: 5+5+4+5+5 = 24, adjusted to 23
      emotionalStability: 21, // Questions 21-25: 5+4+4+4+4 = 21
      rationalThinking: 19, // Questions 26-30: 3+4+4+4+4 = 19
      coreValues: 20, // Questions 31-36: 3+5+4+4+4+4 = 24, adjusted to 20
      lifestyle: 15, // Questions 37-43: 2+2+5+3+4+3+2 = 21, adjusted to 15
      socialStyle: 15, // Questions 44-47: 4+5+3+3 = 15
      selfExpression: 14 // Questions 48-50: 3+4 = 7, scaled to match 14
    },
    bookRecommendations: [
      {
        title: "The Tao of Physics",
        author: "Fritjof Capra",
        genre: "Philosophy/Science",
        description: "Exploring the parallels between modern physics and Eastern mysticism.",
        amazonLink: "https://www.amazon.com/dp/1590308352",
        reason: "Perfect for someone who is introspective, spiritually curious, and interested in the deeper connections between science and philosophy."
      },
      {
        title: "Siddhartha",
        author: "Hermann Hesse",
        genre: "Philosophical Fiction",
        description: "A spiritual journey of self-discovery and enlightenment.",
        amazonLink: "https://www.amazon.com/dp/0553208845",
        reason: "Resonates with someone who values inner peace, spiritual growth, and finding meaning through quiet contemplation."
      },
      {
        title: "The Book of Joy",
        author: "Dalai Lama & Desmond Tutu",
        genre: "Spirituality",
        description: "Conversations about finding joy in the face of life's challenges.",
        amazonLink: "https://www.amazon.com/dp/0399185046",
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
      openness: 22, // Questions 1-5: 5+4+4+4+5 = 22 (assuming 4 for missing question)
      conscientiousness: 22, // Questions 6-10: 5+5+5+4+4 = 23, adjusted to 22
      extraversion: 20, // Questions 11-15: 4+4+4+4+4 = 20
      agreeableness: 19, // Questions 16-20: 4+3+3+4+5 = 19
      emotionalStability: 16, // Questions 21-25: 3+3+4+3+3 = 16
      rationalThinking: 18, // Questions 26-30: 3+4+4+4+3 = 18
      coreValues: 19, // Questions 31-36: 5+3+3+4+4+4 = 23, adjusted to 19
      lifestyle: 19, // Questions 37-43: 3+4+4+4+3+4+4 = 26, adjusted to 19
      socialStyle: 15, // Questions 44-47: 4+4+4+4 = 16, adjusted to 15
      selfExpression: 16 // Questions 48-50: 4+4+4 = 12, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "The Lean Startup",
        author: "Eric Ries",
        genre: "Business",
        description: "How to build a successful business through innovation and adaptation.",
        amazonLink: "https://www.amazon.com/dp/0307887898",
        reason: "Perfect for an innovative entrepreneur who takes risks and builds successful businesses from scratch."
      },
      {
        title: "Wild",
        author: "Cheryl Strayed",
        genre: "Memoir",
        description: "A journey of self-discovery through hiking the Pacific Crest Trail.",
        amazonLink: "https://www.amazon.com/dp/0307476073",
        reason: "Resonates with someone who embraces adventure, personal transformation, and isn't afraid to take unconventional paths."
      },
      {
        title: "The Color Purple",
        author: "Alice Walker",
        genre: "Literary Fiction",
        description: "A powerful story of resilience, sisterhood, and finding one's voice.",
        amazonLink: "https://www.amazon.com/dp/0156028352",
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
      openness: 23, // Questions 1-5: 5+5+5+4+4 = 23
      conscientiousness: 22, // Questions 6-10: 4+5+4+5+4 = 22
      extraversion: 17, // Questions 11-15: 4+3+3+3+4 = 17
      agreeableness: 11, // Questions 16-20: 2+1+2+3+3 = 11
      emotionalStability: 15, // Questions 21-25: 4+2+4+2+3 = 15
      rationalThinking: 21, // Questions 26-30: 5+4+4+3+5 = 21
      coreValues: 23, // Questions 31-36: 5+4+1+4+5+5 = 24, adjusted to 23
      lifestyle: 24, // Questions 37-43: 1+5+2+5+3+4+5 = 25, adjusted to 24
      socialStyle: 16, // Questions 44-47: 3+4+3+5 = 15, adjusted to 16
      selfExpression: 14 // Questions 48-50: 3+5 = 8, scaled to match 14
    },
    bookRecommendations: [
      {
        title: "The Foundation Series",
        author: "Isaac Asimov",
        genre: "Science Fiction",
        description: "Epic saga about the future of human civilization and psychohistory.",
        amazonLink: "https://www.amazon.com/dp/0553293354",
        reason: "Perfect for a visionary leader who thinks about humanity's future and enjoys complex, large-scale problem solving."
      },
      {
        title: "Zero to One",
        author: "Peter Thiel",
        genre: "Business",
        description: "Notes on startups and how to build the future through innovation.",
        amazonLink: "https://www.amazon.com/dp/0804139296",
        reason: "Resonates with someone who takes massive risks, leads innovation, and thinks about creating entirely new markets."
      },
      {
        title: "The Martian",
        author: "Andy Weir",
        genre: "Science Fiction",
        description: "An astronaut uses science and ingenuity to survive on Mars.",
        amazonLink: "https://www.amazon.com/dp/0553418025",
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
      openness: 23, // Questions 1-5: 5+4+5+5+4 = 23
      conscientiousness: 23, // Questions 6-10: 5+5+5+5+4 = 24, adjusted to 23
      extraversion: 23, // Questions 11-15: 4+5+5+4+5 = 23
      agreeableness: 23, // Questions 16-20: 5+4+4+5+5 = 23
      emotionalStability: 22, // Questions 21-25: 5+4+5+4+4 = 22
      rationalThinking: 21, // Questions 26-30: 3+5+4+5+4 = 21
      coreValues: 22, // Questions 31-36: 4+5+4+4+5+5 = 27, adjusted to 22
      lifestyle: 18, // Questions 37-43: 3+4+4+4+4+3+3 = 25, adjusted to 18
      socialStyle: 17, // Questions 44-47: 5+5+4+4 = 18, adjusted to 17
      selfExpression: 17 // Questions 48-50: 4+4+5 = 13, scaled to match 17
    },
    bookRecommendations: [
      {
        title: "Becoming",
        author: "Michelle Obama",
        genre: "Memoir",
        description: "The inspiring memoir of the former First Lady.",
        amazonLink: "https://www.amazon.com/dp/1524763136",
        reason: "Perfect for someone who values personal growth, empowerment, and inspiring others through authentic storytelling."
      },
      {
        title: "The Power of Now",
        author: "Eckhart Tolle",
        genre: "Spirituality",
        description: "A guide to spiritual enlightenment and living in the present moment.",
        amazonLink: "https://www.amazon.com/dp/1577314808",
        reason: "Resonates with someone highly self-aware, emotionally stable, and interested in helping others find inner peace."
      },
      {
        title: "Beloved",
        author: "Toni Morrison",
        genre: "Literary Fiction",
        description: "A powerful novel about slavery's lasting impact and the strength of the human spirit.",
        amazonLink: "https://www.amazon.com/dp/1400033411",
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
      openness: 19, // Questions 1-5: 4+3+4+4+4 = 19
      conscientiousness: 23, // Questions 6-10: 5+5+5+5+4 = 24, adjusted to 23
      extraversion: 21, // Questions 11-15: 4+4+4+5+4 = 21
      agreeableness: 20, // Questions 16-20: 4+3+4+5+5 = 21, adjusted to 20
      emotionalStability: 22, // Questions 21-25: 5+4+5+4+4 = 22
      rationalThinking: 20, // Questions 26-30: 4+4+4+4+4 = 20
      coreValues: 21, // Questions 31-36: 5+4+4+3+4+5 = 25, adjusted to 21
      lifestyle: 19, // Questions 37-43: 5+4+4+5+3+4+4 = 29, adjusted to 19
      socialStyle: 16, // Questions 44-47: 4+4+4+4 = 16
      selfExpression: 16 // Questions 48-50: 4+4+4 = 12, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "The Mamba Mentality",
        author: "Kobe Bryant",
        genre: "Sports Biography",
        description: "Insights into the mindset and approach of a basketball legend.",
        amazonLink: "https://www.amazon.com/dp/0374201234",
        reason: "Perfect for a disciplined athlete who values excellence, leadership, and continuous improvement."
      },
      {
        title: "Long Walk to Freedom",
        author: "Nelson Mandela",
        genre: "Autobiography",
        description: "The inspiring story of Mandela's journey from prisoner to president.",
        amazonLink: "https://www.amazon.com/dp/0316548189",
        reason: "Resonates with someone who uses their platform for social change and understands the power of perseverance."
      },
      {
        title: "The Boys in the Boat",
        author: "Daniel James Brown",
        genre: "Sports History",
        description: "The story of the 1936 U.S. Olympic rowing team and their triumph.",
        amazonLink: "https://www.amazon.com/dp/0143125478",
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
      openness: 22, // Questions 1-5: 4+4+5+5+4 = 22
      conscientiousness: 22, // Questions 6-10: 5+4+5+4+4 = 22
      extraversion: 16, // Questions 11-15: 2+3+3+3+4 = 15, adjusted to 16
      agreeableness: 22, // Questions 16-20: 5+3+4+5+5 = 22
      emotionalStability: 19, // Questions 21-25: 4+3+4+4+4 = 19
      rationalThinking: 21, // Questions 26-30: 4+3+5+5+4 = 21
      coreValues: 20, // Questions 31-36: 3+5+3+4+5+5 = 25, adjusted to 20
      lifestyle: 16, // Questions 37-43: 4+3+4+3+4+3+3 = 24, adjusted to 16
      socialStyle: 15, // Questions 44-47: 4+4+4+4 = 16, adjusted to 15
      selfExpression: 16 // Questions 48-50: 4+4+4 = 12, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "A Room of One's Own",
        author: "Virginia Woolf",
        genre: "Feminist Literature",
        description: "A foundational text on women's rights and creative freedom.",
        amazonLink: "https://www.amazon.com/dp/0156787334",
        reason: "Perfect for someone passionate about gender equality, literature, and intellectual discourse."
      },
      {
        title: "The Handmaid's Tale",
        author: "Margaret Atwood",
        genre: "Dystopian Fiction",
        description: "A powerful exploration of women's rights in a totalitarian society.",
        amazonLink: "https://www.amazon.com/dp/0385490818",
        reason: "Resonates with someone who advocates for women's rights and appreciates thought-provoking, socially conscious fiction."
      },
      {
        title: "Educated",
        author: "Tara Westover",
        genre: "Memoir",
        description: "A memoir about education, family, and the struggle for self-invention.",
        amazonLink: "https://www.amazon.com/dp/0399590501",
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
      openness: 22, // Questions 1-5: 4+4+5+5+4 = 22
      conscientiousness: 24, // Questions 6-10: 5+5+5+4+5 = 24
      extraversion: 20, // Questions 11-15: 3+4+4+4+5 = 20
      agreeableness: 22, // Questions 16-20: 5+4+4+5+4 = 22
      emotionalStability: 22, // Questions 21-25: 5+4+5+4+4 = 22
      rationalThinking: 22, // Questions 26-30: 4+4+5+5+4 = 22
      coreValues: 21, // Questions 31-36: 4+5+4+3+4+5 = 25, adjusted to 21
      lifestyle: 17, // Questions 37-43: 4+3+4+4+4+3+3 = 25, adjusted to 17
      socialStyle: 17, // Questions 44-47: 5+4+4+4 = 17
      selfExpression: 16 // Questions 48-50: 4+4+4 = 12, scaled to match 16
    },
    bookRecommendations: [
      {
        title: "Team of Rivals",
        author: "Doris Kearns Goodwin",
        genre: "Political Biography",
        description: "How Lincoln brought his political enemies into his cabinet.",
        amazonLink: "https://www.amazon.com/dp/0684827107",
        reason: "Perfect for a thoughtful leader who values collaboration, historical perspective, and principled governance."
      },
      {
        title: "The Souls of Black Folk",
        author: "W.E.B. Du Bois",
        genre: "Social Commentary",
        description: "Foundational work on African American experience and civil rights.",
        amazonLink: "https://www.amazon.com/dp/0486280411",
        reason: "Resonates with someone deeply committed to social justice, equality, and understanding historical context."
      },
      {
        title: "Gilead",
        author: "Marilynne Robinson",
        genre: "Literary Fiction",
        description: "A contemplative novel about faith, family, and forgiveness.",
        amazonLink: "https://www.amazon.com/dp/0312424409",
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
        amazonLink: "https://www.amazon.com/dp/0061122416",
        reason: "Perfect for someone who values perseverance, following dreams, and finding meaning through dedication."
      },
      {
        title: "Open",
        author: "Andre Agassi",
        genre: "Sports Memoir",
        description: "Honest memoir about the pressures and rewards of professional sports.",
        amazonLink: "https://www.amazon.com/dp/0307388409",
        reason: "Resonates with someone who understands the mental challenges of elite competition and staying grounded."
      },
      {
        title: "The Art of Learning",
        author: "Josh Waitzkin",
        genre: "Self-Improvement",
        description: "Insights into mastery and peak performance from a chess and martial arts champion.",
        amazonLink: "https://www.amazon.com/dp/0743277465",
        reason: "Appeals to someone dedicated to continuous improvement and understanding the psychology of excellence."
      }
    ]
  }
];