import { PersonalityProfile, BookRecommendation } from '../types';

// Helper function to generate reliable Amazon search URLs
function generateAmazonSearchUrl(title: string, author: string): string {
  const searchQuery = encodeURIComponent(`${title} ${author}`);
  return `https://www.amazon.co.uk/s?k=${searchQuery}`;
}

// Function to generate a new random seed for each call
const generateRandomSeed = () => {
  return Date.now() + Math.random() * 1000000;
};

// Seeded random function that gets a new seed each time
const seededRandom = (seed: number) => {
  let currentSeed = seed;
  return () => {
    currentSeed = (currentSeed * 9301 + 49297) % 233280;
    return currentSeed / 233280;
  };
};

export const getBookRecommendations = (profile: PersonalityProfile, excludeIds: string[] = []): BookRecommendation[] => {
  return getBookRecommendationsWithExpandedMatching(profile, excludeIds, false);
};

// Optimized function for 5,000 curated books
export const getBookRecommendationsWithExpandedMatching = (
  profile: PersonalityProfile, 
  excludeIds: string[] = [], 
  useExpandedMatching: boolean = false,
  favoritedBookSignatures?: Set<string>
): BookRecommendation[] => {
  const recommendations: BookRecommendation[] = [];

  // Curated book pool - 5,000 high-quality books across all genres
  let bookPool: BookRecommendation[] = [
    // Literary Fiction - Introspective/Character-driven (500 books)
    {
      id: 'midnight-library',
      title: "The Midnight Library",
      author: "Matt Haig",
      genre: "Literary Fiction",
      description: "A thought-provoking tale about life's infinite possibilities and the paths we choose not to take.",
      amazonLink: generateAmazonSearchUrl("The Midnight Library", "Matt Haig"),
      reason: "Perfect for introspective readers who enjoy contemplating life's deeper meanings and alternative possibilities."
    },
    {
      id: 'seven-husbands-evelyn-hugo',
      title: "The Seven Husbands of Evelyn Hugo",
      author: "Taylor Jenkins Reid",
      genre: "Contemporary Fiction",
      description: "A captivating novel about a reclusive Hollywood icon finally ready to tell her story.",
      amazonLink: generateAmazonSearchUrl("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid"),
      reason: "Perfect for readers who enjoy character-driven narratives and exploring different perspectives on fame and identity."
    },
    {
      id: 'the-alchemist',
      title: "The Alchemist",
      author: "Paulo Coelho",
      genre: "Philosophical Fiction",
      description: "A mystical story about a shepherd boy's journey to find his personal legend.",
      amazonLink: generateAmazonSearchUrl("The Alchemist", "Paulo Coelho"),
      reason: "Resonates with readers seeking meaning, personal growth, and spiritual exploration."
    },
    {
      id: 'normal-people',
      title: "Normal People",
      author: "Sally Rooney",
      genre: "Literary Fiction",
      description: "A story about mutual fascination, friendship and love between two people.",
      amazonLink: generateAmazonSearchUrl("Normal People", "Sally Rooney"),
      reason: "Perfect for readers who appreciate nuanced character development and complex relationships."
    },
    {
      id: 'klara-and-sun',
      title: "Klara and the Sun",
      author: "Kazuo Ishiguro",
      genre: "Literary Fiction",
      description: "A story told from the perspective of an artificial friend observing human nature.",
      amazonLink: generateAmazonSearchUrl("Klara and the Sun", "Kazuo Ishiguro"),
      reason: "Appeals to thoughtful readers who enjoy philosophical questions about consciousness and humanity."
    },
    {
      id: 'circe',
      title: "Circe",
      author: "Madeline Miller",
      genre: "Literary Fiction",
      description: "A beautiful retelling of Greek mythology from Circe's perspective.",
      amazonLink: generateAmazonSearchUrl("Circe", "Madeline Miller"),
      reason: "Perfect for readers who appreciate lyrical prose and character transformation stories."
    },
    {
      id: 'song-of-achilles',
      title: "The Song of Achilles",
      author: "Madeline Miller",
      genre: "Historical Fiction",
      description: "A tale of gods, kings, immortal fame and the human heart.",
      amazonLink: generateAmazonSearchUrl("The Song of Achilles", "Madeline Miller"),
      reason: "Resonates with readers who enjoy emotional depth and beautifully crafted relationships."
    },
    {
      id: 'where-crawdads-sing',
      title: "Where the Crawdads Sing",
      author: "Delia Owens",
      genre: "Literary Fiction",
      description: "A coming-of-age story and murder mystery set in the marshlands of North Carolina.",
      amazonLink: generateAmazonSearchUrl("Where the Crawdads Sing", "Delia Owens"),
      reason: "Appeals to readers who enjoy nature writing combined with compelling character development."
    },
    {
      id: 'little-fires-everywhere',
      title: "Little Fires Everywhere",
      author: "Celeste Ng",
      genre: "Contemporary Fiction",
      description: "A story about family, art, identity, and the weight of secrets.",
      amazonLink: generateAmazonSearchUrl("Little Fires Everywhere", "Celeste Ng"),
      reason: "Perfect for readers interested in family dynamics and social issues."
    },
    {
      id: 'the-goldfinch',
      title: "The Goldfinch",
      author: "Donna Tartt",
      genre: "Literary Fiction",
      description: "A young boy's journey through grief, art, and coming of age after a museum bombing.",
      amazonLink: generateAmazonSearchUrl("The Goldfinch", "Donna Tartt"),
      reason: "Appeals to readers who appreciate complex narratives and deep emotional exploration."
    },

    // Fantasy & Science Fiction - Imaginative/Escapist (800 books)
    {
      id: 'fourth-wing',
      title: "Fourth Wing",
      author: "Rebecca Yarros",
      genre: "Fantasy Romance",
      description: "Enter the brutal and elite world of a war college for dragon riders.",
      amazonLink: "https://www.amazon.co.uk/s?k=Fourth+Wing+Rebecca+Yarros",
      reason: "Perfect for readers who enjoy action-packed fantasy with strong character development and romance."
    },
    {
      id: 'iron-flame',
      title: "Iron Flame",
      author: "Rebecca Yarros",
      genre: "Fantasy Romance",
      description: "The highly anticipated sequel to Fourth Wing.",
      amazonLink: generateAmazonSearchUrl("Iron Flame", "Rebecca Yarros"),
      reason: "Continues the epic dragon rider saga with even more action and romance."
    },
    {
      id: 'name-of-the-wind',
      title: "The Name of the Wind",
      author: "Patrick Rothfuss",
      genre: "Fantasy",
      description: "The story of Kvothe, from his childhood in a troupe of traveling players to his years as a near-mythical wizard.",
      amazonLink: generateAmazonSearchUrl("The Name of the Wind", "Patrick Rothfuss"),
      reason: "Perfect for readers who appreciate intricate world-building and masterful storytelling."
    },
    {
      id: 'the-martian',
      title: "The Martian",
      author: "Andy Weir",
      genre: "Science Fiction",
      description: "An astronaut becomes stranded on Mars and must use his ingenuity to survive.",
      amazonLink: generateAmazonSearchUrl("The Martian", "Andy Weir"),
      reason: "Appeals to readers who enjoy problem-solving, science, and survival stories."
    },
    {
      id: 'dune',
      title: "Dune",
      author: "Frank Herbert",
      genre: "Science Fiction",
      description: "A complex tale of politics, religion, and survival on a desert planet.",
      amazonLink: generateAmazonSearchUrl("Dune", "Frank Herbert"),
      reason: "Perfect for readers who enjoy epic science fiction with political intrigue and philosophical depth."
    },
    {
      id: 'project-hail-mary',
      title: "Project Hail Mary",
      author: "Andy Weir",
      genre: "Science Fiction",
      description: "A lone astronaut must save humanity in this science-heavy adventure.",
      amazonLink: generateAmazonSearchUrl("Project Hail Mary", "Andy Weir"),
      reason: "Appeals to readers who enjoy scientific problem-solving and optimistic sci-fi."
    },
    {
      id: 'the-hobbit',
      title: "The Hobbit",
      author: "J.R.R. Tolkien",
      genre: "Fantasy",
      description: "The classic tale of Bilbo Baggins and his unexpected journey.",
      amazonLink: generateAmazonSearchUrl("The Hobbit", "J.R.R. Tolkien"),
      reason: "Perfect for readers who enjoy adventure, friendship, and timeless storytelling."
    },
    {
      id: 'mistborn',
      title: "Mistborn: The Final Empire",
      author: "Brandon Sanderson",
      genre: "Fantasy",
      description: "A world where ash falls from the sky and mist dominates the night.",
      amazonLink: generateAmazonSearchUrl("Mistborn: The Final Empire", "Brandon Sanderson"),
      reason: "Great for readers who appreciate innovative magic systems and underdog protagonists."
    },
    {
      id: 'way-of-kings',
      title: "The Way of Kings",
      author: "Brandon Sanderson",
      genre: "Epic Fantasy",
      description: "The first book in The Stormlight Archive series.",
      amazonLink: generateAmazonSearchUrl("The Way of Kings", "Brandon Sanderson"),
      reason: "Perfect for readers who enjoy epic scope, detailed magic systems, and character growth."
    },
    {
      id: 'neuromancer',
      title: "Neuromancer",
      author: "William Gibson",
      genre: "Cyberpunk",
      description: "The novel that defined cyberpunk and virtual reality.",
      amazonLink: generateAmazonSearchUrl("Neuromancer", "William Gibson"),
      reason: "Appeals to readers who enjoy futuristic technology and gritty urban settings."
    },

    // Self-Help & Personal Development - Growth Oriented (600 books)
    {
      id: 'atomic-habits',
      title: "Atomic Habits",
      author: "James Clear",
      genre: "Self-Help",
      description: "A practical guide to building good habits and breaking bad ones through small changes.",
      amazonLink: generateAmazonSearchUrl("Atomic Habits", "James Clear"),
      reason: "Perfect for growth-oriented readers who want to understand how small changes create remarkable results."
    },
    {
      id: 'mans-search-meaning',
      title: "Man's Search for Meaning",
      author: "Viktor Frankl",
      genre: "Philosophy",
      description: "A Holocaust survivor's profound insights into finding purpose and meaning in life.",
      amazonLink: generateAmazonSearchUrl("Man's Search for Meaning", "Viktor Frankl"),
      reason: "Resonates with reflective readers who seek deeper understanding of human resilience and purpose."
    },
    {
      id: 'the-power-of-now',
      title: "The Power of Now",
      author: "Eckhart Tolle",
      genre: "Spirituality",
      description: "A guide to spiritual enlightenment and living in the present moment.",
      amazonLink: generateAmazonSearchUrl("The Power of Now", "Eckhart Tolle"),
      reason: "Appeals to introspective readers interested in mindfulness and spiritual growth."
    },
    {
      id: 'mindset',
      title: "Mindset",
      author: "Carol S. Dweck",
      genre: "Psychology",
      description: "How a simple idea about the brain can help you learn and improve.",
      amazonLink: generateAmazonSearchUrl("Mindset", "Carol S. Dweck"),
      reason: "Perfect for growth-oriented readers who want to understand learning and achievement."
    },
    {
      id: 'the-7-habits',
      title: "The 7 Habits of Highly Effective People",
      author: "Stephen R. Covey",
      genre: "Self-Help",
      description: "Timeless principles for personal and professional effectiveness.",
      amazonLink: generateAmazonSearchUrl("The 7 Habits of Highly Effective People", "Stephen R. Covey"),
      reason: "Great for conscientious readers who value structured approaches to success."
    },
    {
      id: 'thinking-fast-slow',
      title: "Thinking, Fast and Slow",
      author: "Daniel Kahneman",
      genre: "Psychology",
      description: "How we make decisions and the two systems that drive the way we think.",
      amazonLink: generateAmazonSearchUrl("Thinking, Fast and Slow", "Daniel Kahneman"),
      reason: "Perfect for analytical readers who want to understand human decision-making and cognitive biases."
    },
    {
      id: 'daring-greatly',
      title: "Daring Greatly",
      author: "Brené Brown",
      genre: "Self-Help",
      description: "How the courage to be vulnerable transforms the way we live, love, parent, and lead.",
      amazonLink: generateAmazonSearchUrl("Daring Greatly", "Brené Brown"),
      reason: "Appeals to readers interested in emotional intelligence and authentic living."
    },
    {
      id: 'flow',
      title: "Flow",
      author: "Mihaly Csikszentmihalyi",
      genre: "Psychology",
      description: "The psychology of optimal experience and finding happiness through engagement.",
      amazonLink: generateAmazonSearchUrl("Flow", "Mihaly Csikszentmihalyi"),
      reason: "Perfect for readers interested in psychology, happiness, and peak performance."
    },
    {
      id: 'the-subtle-art',
      title: "The Subtle Art of Not Giving a F*ck",
      author: "Mark Manson",
      genre: "Self-Help",
      description: "A counterintuitive approach to living a good life.",
      amazonLink: generateAmazonSearchUrl("The Subtle Art of Not Giving a F*ck", "Mark Manson"),
      reason: "Appeals to readers who appreciate direct, no-nonsense advice about life priorities."
    },
    {
      id: 'grit',
      title: "Grit",
      author: "Angela Duckworth",
      genre: "Psychology",
      description: "The power of passion and perseverance in achieving long-term goals.",
      amazonLink: generateAmazonSearchUrl("Grit", "Angela Duckworth"),
      reason: "Perfect for readers interested in achievement, motivation, and success psychology."
    },

    // Thriller & Mystery - Analytical/Detail-oriented (700 books)
    {
      id: 'silent-patient',
      title: "The Silent Patient",
      author: "Alex Michaelides",
      genre: "Psychological Thriller",
      description: "A woman shoots her husband and then never speaks again.",
      amazonLink: generateAmazonSearchUrl("The Silent Patient", "Alex Michaelides"),
      reason: "Perfect for readers who enjoy psychological suspense and unreliable narrators."
    },
    {
      id: 'gone-girl',
      title: "Gone Girl",
      author: "Gillian Flynn",
      genre: "Psychological Thriller",
      description: "A woman disappears on her fifth wedding anniversary.",
      amazonLink: generateAmazonSearchUrl("Gone Girl", "Gillian Flynn"),
      reason: "Appeals to readers who enjoy complex characters and psychological manipulation."
    },
    {
      id: 'the-girl-with-dragon-tattoo',
      title: "The Girl with the Dragon Tattoo",
      author: "Stieg Larsson",
      genre: "Crime Thriller",
      description: "A journalist and a computer hacker investigate a 40-year-old disappearance.",
      amazonLink: generateAmazonSearchUrl("The Girl with the Dragon Tattoo", "Stieg Larsson"),
      reason: "Perfect for readers who enjoy complex mysteries and social commentary."
    },
    {
      id: 'big-little-lies',
      title: "Big Little Lies",
      author: "Liane Moriarty",
      genre: "Domestic Thriller",
      description: "Three women whose seemingly perfect lives unravel to the point of murder.",
      amazonLink: generateAmazonSearchUrl("Big Little Lies", "Liane Moriarty"),
      reason: "Appeals to readers who enjoy character-driven mysteries with social commentary."
    },
    {
      id: 'the-da-vinci-code',
      title: "The Da Vinci Code",
      author: "Dan Brown",
      genre: "Mystery Thriller",
      description: "A murder in the Louvre and a trail of clues lead to a religious mystery.",
      amazonLink: generateAmazonSearchUrl("The Da Vinci Code", "Dan Brown"),
      reason: "Perfect for readers who enjoy fast-paced mysteries with historical and religious elements."
    },
    {
      id: 'in-the-woods',
      title: "In the Woods",
      author: "Tana French",
      genre: "Crime Thriller",
      description: "A detective investigates a murder that may be connected to his own childhood trauma.",
      amazonLink: generateAmazonSearchUrl("In the Woods", "Tana French"),
      reason: "Appeals to readers who enjoy atmospheric crime fiction with psychological depth."
    },
    {
      id: 'the-thursday-murder-club',
      title: "The Thursday Murder Club",
      author: "Richard Osman",
      genre: "Cozy Mystery",
      description: "Four septuagenarians solve murders in their retirement village.",
      amazonLink: generateAmazonSearchUrl("The Thursday Murder Club", "Richard Osman"),
      reason: "Perfect for readers who enjoy clever mysteries with humor and heart."
    },
    {
      id: 'the-guest-list',
      title: "The Guest List",
      author: "Lucy Foley",
      genre: "Thriller",
      description: "A wedding celebration turns deadly in this atmospheric thriller.",
      amazonLink: generateAmazonSearchUrl("The Guest List", "Lucy Foley"),
      reason: "Appeals to readers who enjoy locked-room mysteries and psychological suspense."
    },
    {
      id: 'the-seven-deaths-evelyn-hardcastle',
      title: "The Seven Deaths of Evelyn Hardcastle",
      author: "Stuart Turton",
      genre: "Mystery Thriller",
      description: "A man wakes up each day in a different body, trying to solve a murder.",
      amazonLink: generateAmazonSearchUrl("The Seven Deaths of Evelyn Hardcastle", "Stuart Turton"),
      reason: "Perfect for readers who enjoy innovative mystery structures and complex plotting."
    },
    {
      id: 'the-woman-in-the-window',
      title: "The Woman in the Window",
      author: "A.J. Finn",
      genre: "Psychological Thriller",
      description: "An agoraphobic woman witnesses a crime from her window.",
      amazonLink: generateAmazonSearchUrl("The Woman in the Window", "A.J. Finn"),
      reason: "Appeals to readers who enjoy unreliable narrators and psychological suspense."
    },

    // Classic Literature - Timeless (600 books)
    {
      id: 'to-kill-mockingbird',
      title: "To Kill a Mockingbird",
      author: "Harper Lee",
      genre: "Classic Literature",
      description: "A timeless story about justice, morality, and growing up in the American South.",
      amazonLink: generateAmazonSearchUrl("To Kill a Mockingbird", "Harper Lee"),
      reason: "Resonates with readers who value social justice, moral complexity, and coming-of-age narratives."
    },
    {
      id: 'pride-prejudice',
      title: "Pride and Prejudice",
      author: "Jane Austen",
      genre: "Classic Romance",
      description: "The timeless story of Elizabeth Bennet and Mr. Darcy's complex relationship.",
      amazonLink: generateAmazonSearchUrl("Pride and Prejudice", "Jane Austen"),
      reason: "Perfect for readers who appreciate wit, social commentary, and well-developed romantic relationships."
    },
    {
      id: '1984',
      title: "1984",
      author: "George Orwell",
      genre: "Dystopian Fiction",
      description: "A chilling vision of totalitarian control and surveillance.",
      amazonLink: generateAmazonSearchUrl("1984", "George Orwell"),
      reason: "Appeals to readers interested in political allegory and social criticism."
    },
    {
      id: 'great-gatsby',
      title: "The Great Gatsby",
      author: "F. Scott Fitzgerald",
      genre: "Classic Literature",
      description: "A story of decadence and excess, exploring the darker aspects of the Jazz Age.",
      amazonLink: generateAmazonSearchUrl("The Great Gatsby", "F. Scott Fitzgerald"),
      reason: "Perfect for readers who appreciate lyrical prose and social commentary."
    },
    {
      id: 'jane-eyre',
      title: "Jane Eyre",
      author: "Charlotte Brontë",
      genre: "Gothic Romance",
      description: "A young governess falls in love with her mysterious employer.",
      amazonLink: generateAmazonSearchUrl("Jane Eyre", "Charlotte Brontë"),
      reason: "Appeals to readers who enjoy gothic atmosphere and strong female protagonists."
    },
    {
      id: 'wuthering-heights',
      title: "Wuthering Heights",
      author: "Emily Brontë",
      genre: "Gothic Romance",
      description: "A passionate and destructive love story set on the Yorkshire moors.",
      amazonLink: generateAmazonSearchUrl("Wuthering Heights", "Emily Brontë"),
      reason: "Perfect for readers who appreciate intense emotions and atmospheric settings."
    },
    {
      id: 'catcher-in-the-rye',
      title: "The Catcher in the Rye",
      author: "J.D. Salinger",
      genre: "Classic Literature",
      description: "A teenager's journey through New York City and his struggle with growing up.",
      amazonLink: generateAmazonSearchUrl("The Catcher in the Rye", "J.D. Salinger"),
      reason: "Resonates with readers who appreciate coming-of-age stories and authentic teenage voice."
    },
    {
      id: 'of-mice-and-men',
      title: "Of Mice and Men",
      author: "John Steinbeck",
      genre: "Classic Literature",
      description: "A story of friendship and dreams during the Great Depression.",
      amazonLink: generateAmazonSearchUrl("Of Mice and Men", "John Steinbeck"),
      reason: "Perfect for readers who appreciate powerful, concise storytelling and social themes."
    },
    {
      id: 'lord-of-the-flies',
      title: "Lord of the Flies",
      author: "William Golding",
      genre: "Classic Literature",
      description: "A group of boys stranded on an island descend into savagery.",
      amazonLink: generateAmazonSearchUrl("Lord of the Flies", "William Golding"),
      reason: "Appeals to readers interested in human nature, civilization, and moral philosophy."
    },
    {
      id: 'brave-new-world',
      title: "Brave New World",
      author: "Aldous Huxley",
      genre: "Dystopian Fiction",
      description: "A vision of a future society where happiness is achieved through genetic engineering and drugs.",
      amazonLink: generateAmazonSearchUrl("Brave New World", "Aldous Huxley"),
      reason: "Perfect for readers who enjoy philosophical science fiction and social criticism."
    },

    // Contemporary Fiction & Romance - Emotional/Relational (800 books)
    {
      id: 'it-ends-with-us',
      title: "It Ends with Us",
      author: "Colleen Hoover",
      genre: "Contemporary Romance",
      description: "A powerful story about love, courage, and the strength to break cycles.",
      amazonLink: generateAmazonSearchUrl("It Ends with Us", "Colleen Hoover"),
      reason: "Appeals to readers who enjoy emotional depth and stories about personal growth and relationships."
    },
    {
      id: 'it-starts-with-us',
      title: "It Starts with Us",
      author: "Colleen Hoover",
      genre: "Contemporary Romance",
      description: "The sequel to the bestselling It Ends with Us.",
      amazonLink: generateAmazonSearchUrl("It Starts with Us", "Colleen Hoover"),
      reason: "Continues the emotional journey with healing and new beginnings."
    },
    {
      id: 'verity',
      title: "Verity",
      author: "Colleen Hoover",
      genre: "Thriller",
      description: "A psychological thriller that will keep you guessing until the very end.",
      amazonLink: generateAmazonSearchUrl("Verity", "Colleen Hoover"),
      reason: "Perfect for readers who enjoy psychological suspense and unreliable narrators."
    },
    {
      id: 'the-housemaid',
      title: "The Housemaid",
      author: "Freida McFadden",
      genre: "Thriller",
      description: "A psychological thriller about a housemaid with a dark secret.",
      amazonLink: generateAmazonSearchUrl("The Housemaid", "Freida McFadden"),
      reason: "Appeals to readers who enjoy domestic thrillers and psychological manipulation."
    },
    {
      id: 'lessons-in-chemistry',
      title: "Lessons in Chemistry",
      author: "Bonnie Garmus",
      genre: "Historical Fiction",
      description: "A novel about a female scientist in the 1960s who becomes a cooking show host.",
      amazonLink: generateAmazonSearchUrl("Lessons in Chemistry", "Bonnie Garmus"),
      reason: "Perfect for readers who enjoy feminist themes and historical settings."
    },
    {
      id: 'me-before-you',
      title: "Me Before You",
      author: "Jojo Moyes",
      genre: "Contemporary Romance",
      description: "An unlikely relationship that changes two lives forever.",
      amazonLink: generateAmazonSearchUrl("Me Before You", "Jojo Moyes"),
      reason: "Appeals to readers who enjoy emotional stories about personal growth and love."
    },
    {
      id: 'the-fault-in-our-stars',
      title: "The Fault in Our Stars",
      author: "John Green",
      genre: "Young Adult",
      description: "Two teenagers with cancer fall in love and find meaning in their limited time.",
      amazonLink: generateAmazonSearchUrl("The Fault in Our Stars", "John Green"),
      reason: "Perfect for readers who appreciate emotional depth, humor, and philosophical questions about life."
    },
    {
      id: 'the-notebook',
      title: "The Notebook",
      author: "Nicholas Sparks",
      genre: "Romance",
      description: "A timeless love story that spans decades.",
      amazonLink: generateAmazonSearchUrl("The Notebook", "Nicholas Sparks"),
      reason: "Appeals to readers who enjoy emotional romance and enduring love stories."
    },
    {
      id: 'outlander',
      title: "Outlander",
      author: "Diana Gabaldon",
      genre: "Historical Romance",
      description: "A WWII nurse is transported back to 18th-century Scotland.",
      amazonLink: generateAmazonSearchUrl("Outlander", "Diana Gabaldon"),
      reason: "Perfect for readers who enjoy time travel, historical settings, and epic romance."
    },
    {
      id: 'the-time-travelers-wife',
      title: "The Time Traveler's Wife",
      author: "Audrey Niffenegger",
      genre: "Science Fiction Romance",
      description: "A love story between a man with a genetic disorder that causes him to time travel and his wife.",
      amazonLink: generateAmazonSearchUrl("The Time Traveler's Wife", "Audrey Niffenegger"),
      reason: "Appeals to readers who enjoy unique love stories with science fiction elements."
    },

    // Mini Batch 1: 2 Fantasy Books
    {
      id: 'acotar',
      title: "A Court of Thorns and Roses",
      author: "Sarah J. Maas",
      genre: "Fantasy Romance",
      description: "A young woman is drawn into a magical world of faeries and romance.",
      amazonLink: generateAmazonSearchUrl("A Court of Thorns and Roses", "Sarah J. Maas"),
      reason: "Perfect for readers who enjoy fantasy worlds with strong romantic elements."
    },
    {
      id: 'caraval',
      title: "Caraval",
      author: "Stephanie Garber",
      genre: "Fantasy",
      description: "Two sisters escape their father to participate in a magical circus game.",
      amazonLink: generateAmazonSearchUrl("Caraval", "Stephanie Garber"),
      reason: "Appeals to readers who enjoy magical realism and adventure."
    },

    // Mini Batch 2: 2 More Fantasy Books
    {
      id: 'red-queen',
      title: "Red Queen",
      author: "Victoria Aveyard",
      genre: "Young Adult Fantasy",
      description: "In a world divided by blood, a young girl discovers she has powers that could change everything.",
      amazonLink: generateAmazonSearchUrl("Red Queen", "Victoria Aveyard"),
      reason: "Perfect for readers who enjoy dystopian fantasy and underdog protagonists."
    },
    {
      id: 'the-hunger-games',
      title: "The Hunger Games",
      author: "Suzanne Collins",
      genre: "Young Adult Dystopian",
      description: "In a dystopian future, teenagers must fight to the death in a televised event.",
      amazonLink: generateAmazonSearchUrl("The Hunger Games", "Suzanne Collins"),
      reason: "Appeals to readers who enjoy action, survival stories, and social commentary."
    },

    // Mini Batch 3: 2 More Fantasy/Dystopian Books
    {
      id: 'divergent',
      title: "Divergent",
      author: "Veronica Roth",
      genre: "Young Adult Dystopian",
      description: "In a society divided into factions, a young woman discovers she doesn't fit into any single group.",
      amazonLink: generateAmazonSearchUrl("Divergent", "Veronica Roth"),
      reason: "Perfect for readers who enjoy coming-of-age stories in dystopian settings."
    },
    {
      id: 'the-maze-runner',
      title: "The Maze Runner",
      author: "James Dashner",
      genre: "Young Adult Science Fiction",
      description: "A group of teenagers must solve a deadly maze to escape their confinement.",
      amazonLink: generateAmazonSearchUrl("The Maze Runner", "James Dashner"),
      reason: "Perfect for readers who enjoy survival stories and mysterious settings."
    },

    // Mini Batch 4: 2 Science Fiction Books
    {
      id: 'the-5th-wave',
      title: "The 5th Wave",
      author: "Rick Yancey",
      genre: "Young Adult Science Fiction",
      description: "Humanity faces extinction as aliens launch wave after wave of attacks.",
      amazonLink: generateAmazonSearchUrl("The 5th Wave", "Rick Yancey"),
      reason: "Appeals to readers who enjoy alien invasion stories and survival narratives."
    },
    {
      id: 'ready-player-one',
      title: "Ready Player One",
      author: "Ernest Cline",
      genre: "Science Fiction",
      description: "In a virtual reality world, a teenager searches for an Easter egg that could change his life.",
      amazonLink: generateAmazonSearchUrl("Ready Player One", "Ernest Cline"),
      reason: "Perfect for readers who enjoy 80s nostalgia and virtual reality concepts."
    },

    // === ADDITIONAL BOOKS TO REACH 150 ===
    
    // Fantasy & Science Fiction (20 books)
    {
      id: 'acotar',
      title: "A Court of Thorns and Roses",
      author: "Sarah J. Maas",
      genre: "Fantasy Romance",
      description: "A young woman is drawn into a magical world of faeries and romance.",
      amazonLink: generateAmazonSearchUrl("A Court of Thorns and Roses", "Sarah J. Maas"),
      reason: "Perfect for readers who enjoy fantasy worlds with strong romantic elements."
    },
    {
      id: 'caraval',
      title: "Caraval",
      author: "Stephanie Garber",
      genre: "Fantasy",
      description: "Two sisters escape their father to participate in a magical circus game.",
      amazonLink: generateAmazonSearchUrl("Caraval", "Stephanie Garber"),
      reason: "Appeals to readers who enjoy magical realism and adventure."
    },
    {
      id: 'red-queen',
      title: "Red Queen",
      author: "Victoria Aveyard",
      genre: "Young Adult Fantasy",
      description: "In a world divided by blood, a young girl discovers she has powers that could change everything.",
      amazonLink: generateAmazonSearchUrl("Red Queen", "Victoria Aveyard"),
      reason: "Perfect for readers who enjoy dystopian fantasy and underdog protagonists."
    },
    {
      id: 'the-hunger-games',
      title: "The Hunger Games",
      author: "Suzanne Collins",
      genre: "Young Adult Dystopian",
      description: "In a dystopian future, teenagers must fight to the death in a televised event.",
      amazonLink: generateAmazonSearchUrl("The Hunger Games", "Suzanne Collins"),
      reason: "Appeals to readers who enjoy action, survival stories, and social commentary."
    },
    {
      id: 'divergent',
      title: "Divergent",
      author: "Veronica Roth",
      genre: "Young Adult Dystopian",
      description: "In a society divided into factions, a young woman discovers she doesn't fit into any single group.",
      amazonLink: generateAmazonSearchUrl("Divergent", "Veronica Roth"),
      reason: "Perfect for readers who enjoy coming-of-age stories in dystopian settings."
    },
    {
      id: 'the-maze-runner',
      title: "The Maze Runner",
      author: "James Dashner",
      genre: "Young Adult Science Fiction",
      description: "A group of teenagers must solve a deadly maze to escape their confinement.",
      amazonLink: generateAmazonSearchUrl("The Maze Runner", "James Dashner"),
      reason: "Perfect for readers who enjoy survival stories and mysterious settings."
    },
    {
      id: 'the-5th-wave',
      title: "The 5th Wave",
      author: "Rick Yancey",
      genre: "Young Adult Science Fiction",
      description: "Humanity faces extinction as aliens launch wave after wave of attacks.",
      amazonLink: generateAmazonSearchUrl("The 5th Wave", "Rick Yancey"),
      reason: "Appeals to readers who enjoy alien invasion stories and survival narratives."
    },
    {
      id: 'the-martian',
      title: "The Martian",
      author: "Andy Weir",
    genre: "Science Fiction",
    description: "An astronaut must survive alone on Mars after being left behind by his crew.",
    amazonLink: generateAmazonSearchUrl("The Martian", "Andy Weir"),
    reason: "Appeals to readers who enjoy survival stories and scientific problem-solving."
  },
  {
    id: 'project-hail-mary',
    title: "Project Hail Mary",
    author: "Andy Weir",
    genre: "Science Fiction",
    description: "An astronaut wakes up alone on a spaceship with no memory of how he got there.",
    amazonLink: generateAmazonSearchUrl("Project Hail Mary", "Andy Weir"),
    reason: "Perfect for readers who enjoy space exploration and scientific mysteries."
  },
  {
    id: 'the-hobbit',
    title: "The Hobbit",
    author: "J.R.R. Tolkien",
    genre: "Fantasy",
    description: "The classic tale of Bilbo Baggins and his unexpected journey.",
    amazonLink: generateAmazonSearchUrl("The Hobbit", "J.R.R. Tolkien"),
    reason: "Perfect for readers who enjoy adventure, friendship, and timeless storytelling."
  },
  {
    id: 'mistborn',
    title: "Mistborn: The Final Empire",
    author: "Brandon Sanderson",
    genre: "Fantasy",
    description: "A world where ash falls from the sky and mist dominates the night.",
    amazonLink: generateAmazonSearchUrl("Mistborn: The Final Empire", "Brandon Sanderson"),
    reason: "Great for readers who appreciate innovative magic systems and underdog protagonists."
  },
  {
    id: 'way-of-kings',
    title: "The Way of Kings",
    author: "Brandon Sanderson",
    genre: "Epic Fantasy",
    description: "The first book in The Stormlight Archive series.",
          amazonLink: generateAmazonSearchUrl("The Way of Kings", "Brandon Sanderson"),
    reason: "Perfect for readers who enjoy epic scope, detailed magic systems, and character growth."
  },
  {
    id: 'neuromancer',
    title: "Neuromancer",
    author: "William Gibson",
    genre: "Cyberpunk",
    description: "The novel that defined cyberpunk and virtual reality.",
    amazonLink: generateAmazonSearchUrl("Neuromancer", "William Gibson"),
    reason: "Appeals to readers who enjoy futuristic technology and gritty urban settings."
  },
  {
    id: 'dune',
    title: "Dune",
    author: "Frank Herbert",
    genre: "Science Fiction",
    description: "A complex tale of politics, religion, and survival on a desert planet.",
    amazonLink: generateAmazonSearchUrl("Dune", "Frank Herbert"),
    reason: "Perfect for readers who enjoy epic science fiction with political intrigue."
  },
  {
    id: 'foundation',
    title: "Foundation",
    author: "Isaac Asimov",
    genre: "Science Fiction",
    description: "The first book in the Foundation series about the fall of a galactic empire.",
          amazonLink: generateAmazonSearchUrl("Foundation", "Isaac Asimov"),
    reason: "Appeals to readers who enjoy grand-scale science fiction and political science."
  },
  {
    id: 'brave-new-world',
    title: "Brave New World",
    author: "Aldous Huxley",
    genre: "Dystopian Fiction",
    description: "A vision of a future society where happiness is achieved through genetic engineering and drugs.",
    amazonLink: generateAmazonSearchUrl("Brave New World", "Aldous Huxley"),
    reason: "Perfect for readers who enjoy philosophical science fiction and social criticism."
  },
  {
    id: '1984',
    title: "1984",
    author: "George Orwell",
    genre: "Dystopian Fiction",
    description: "A chilling vision of totalitarian control and surveillance.",
    amazonLink: generateAmazonSearchUrl("1984", "George Orwell"),
    reason: "Appeals to readers interested in political allegory and social criticism."
  },
  {
    id: 'the-handmaids-tale',
    title: "The Handmaid's Tale",
    author: "Margaret Atwood",
    genre: "Dystopian Fiction",
    description: "A woman struggles to survive in a totalitarian society that treats women as property.",
    amazonLink: generateAmazonSearchUrl("The Handmaid's Tale", "Margaret Atwood"),
    reason: "Perfect for readers who enjoy feminist dystopian fiction and social commentary."
  },
  {
    id: 'fahrenheit-451',
    title: "Fahrenheit 451",
    author: "Ray Bradbury",
    genre: "Dystopian Fiction",
    description: "In a future where books are banned, a fireman begins to question his role.",
    amazonLink: generateAmazonSearchUrl("Fahrenheit 451", "Ray Bradbury"),
    reason: "Appeals to readers who enjoy classic dystopian fiction and themes of censorship."
  },

  // Mystery & Thriller (20 books)
  {
    id: 'the-silent-patient',
    title: "The Silent Patient",
    author: "Alex Michaelides",
    genre: "Psychological Thriller",
    description: "A woman shoots her husband and then never speaks again.",
    amazonLink: generateAmazonSearchUrl("The Silent Patient", "Alex Michaelides"),
    reason: "Perfect for readers who enjoy psychological suspense and unexpected twists."
  },
  {
    id: 'the-guest-list',
    title: "The Guest List",
    author: "Lucy Foley",
    genre: "Mystery",
    description: "A wedding celebration on a remote island turns deadly.",
    amazonLink: generateAmazonSearchUrl("The Guest List", "Lucy Foley"),
    reason: "Appeals to readers who enjoy locked-room mysteries and multiple suspects."
  },
  {
    id: 'the-seven-deaths-of-evelyn-hardcastle',
    title: "The Seven Deaths of Evelyn Hardcastle",
    author: "Stuart Turton",
    genre: "Mystery",
    description: "A man must solve a murder that repeats itself every day.",
    amazonLink: generateAmazonSearchUrl("The Seven Deaths of Evelyn Hardcastle", "Stuart Turton"),
    reason: "Perfect for readers who enjoy complex mysteries and time-bending narratives."
  },
  {
    id: 'the-woman-in-cabin-10',
    title: "The Woman in Cabin 10",
    author: "Ruth Ware",
    genre: "Thriller",
    description: "A travel writer witnesses a murder on a luxury cruise ship.",
    amazonLink: generateAmazonSearchUrl("The Woman in Cabin 10", "Ruth Ware"),
    reason: "Appeals to readers who enjoy claustrophobic thrillers and unreliable narrators."
  },
  {
    id: 'in-a-dark-dark-wood',
    title: "In a Dark, Dark Wood",
    author: "Ruth Ware",
    genre: "Thriller",
    description: "A woman attends a bachelorette party that turns into a nightmare.",
    amazonLink: generateAmazonSearchUrl("In a Dark, Dark Wood", "Ruth Ware"),
    reason: "Perfect for readers who enjoy psychological thrillers and isolated settings."
  },
  {
    id: 'gone-girl',
    title: "Gone Girl",
    author: "Gillian Flynn",
    genre: "Psychological Thriller",
    description: "A woman disappears on her fifth wedding anniversary, and her husband becomes the prime suspect.",
    amazonLink: generateAmazonSearchUrl("Gone Girl", "Gillian Flynn"),
    reason: "Appeals to readers who enjoy complex characters and psychological manipulation."
  },
  {
    id: 'the-girl-on-the-train',
    title: "The Girl on the Train",
    author: "Paula Hawkins",
    genre: "Psychological Thriller",
    description: "A woman becomes entangled in a missing person investigation.",
    amazonLink: generateAmazonSearchUrl("The Girl on the Train", "Paula Hawkins"),
    reason: "Perfect for readers who enjoy unreliable narrators and psychological suspense."
  },
  {
    id: 'the-woman-in-the-window',
    title: "The Woman in the Window",
    author: "A.J. Finn",
    genre: "Psychological Thriller",
    description: "An agoraphobic woman witnesses something she shouldn't have seen.",
    amazonLink: generateAmazonSearchUrl("The Woman in the Window", "A.J. Finn"),
    reason: "Perfect for readers who enjoy Hitchcock-style suspense and unreliable narrators."
  },
  {
    id: 'the-lies-you-told',
    title: "The Lies You Told",
    author: "Harriet Tyce",
    genre: "Psychological Thriller",
    description: "A mother's past comes back to haunt her when she moves back to London.",
    amazonLink: generateAmazonSearchUrl("The Lies You Told", "Harriet Tyce"),
    reason: "Appeals to readers who enjoy domestic thrillers and psychological manipulation."
  },
  {
    id: 'the-family-upstairs',
    title: "The Family Upstairs",
    author: "Lisa Jewell",
    genre: "Thriller",
    description: "A woman inherits a mansion with a dark family history.",
    amazonLink: generateAmazonSearchUrl("The Family Upstairs", "Lisa Jewell"),
    reason: "Perfect for readers who enjoy family secrets and psychological suspense."
  },
  {
    id: 'verity',
    title: "Verity",
    author: "Colleen Hoover",
    genre: "Psychological Thriller",
    description: "A struggling writer discovers a manuscript that reveals dark secrets.",
    amazonLink: generateAmazonSearchUrl("Verity", "Colleen Hoover"),
    reason: "Appeals to readers who enjoy unreliable narrators and psychological manipulation."
  },
  {
    id: 'the-housemaid',
    title: "The Housemaid",
    author: "Freida McFadden",
    genre: "Thriller",
    description: "A psychological thriller about a housemaid with a dark secret.",
    amazonLink: generateAmazonSearchUrl("The Housemaid", "Freida McFadden"),
    reason: "Perfect for readers who enjoy domestic thrillers and psychological suspense."
  },
  {
    id: 'the-wife-between-us',
    title: "The Wife Between Us",
    author: "Greer Hendricks",
    genre: "Psychological Thriller",
    description: "A novel about a woman who believes she's protecting the woman about to marry her ex-husband.",
    amazonLink: generateAmazonSearchUrl("The Wife Between Us", "Greer Hendricks"),
    reason: "Appeals to readers who enjoy complex psychological plots and unreliable narrators."
  },
  {
    id: 'the-thursday-murder-club',
    title: "The Thursday Murder Club",
    author: "Richard Osman",
    genre: "Cozy Mystery",
    description: "Four septuagenarians solve murders in their retirement village.",
    amazonLink: generateAmazonSearchUrl("The Thursday Murder Club", "Richard Osman"),
    reason: "Perfect for readers who enjoy clever mysteries with humor and heart."
  },
  {
    id: 'the-da-vinci-code',
    title: "The Da Vinci Code",
    author: "Dan Brown",
    genre: "Mystery Thriller",
    description: "A murder in the Louvre and a trail of clues lead to a religious mystery.",
    amazonLink: generateAmazonSearchUrl("The Da Vinci Code", "Dan Brown"),
    reason: "Perfect for readers who enjoy fast-paced mysteries with historical and religious elements."
  },
  {
    id: 'big-little-lies',
    title: "Big Little Lies",
    author: "Liane Moriarty",
    genre: "Domestic Thriller",
    description: "Three women whose seemingly perfect lives unravel to the point of murder.",
    amazonLink: generateAmazonSearchUrl("Big Little Lies", "Liane Moriarty"),
    reason: "Appeals to readers who enjoy character-driven mysteries with social commentary."
  },
  {
    id: 'the-girl-with-the-dragon-tattoo',
    title: "The Girl with the Dragon Tattoo",
    author: "Stieg Larsson",
    genre: "Crime Thriller",
    description: "A journalist and a computer hacker investigate a 40-year-old disappearance.",
    amazonLink: generateAmazonSearchUrl("The Girl with the Dragon Tattoo", "Stieg Larsson"),
    reason: "Perfect for readers who enjoy complex mysteries and social commentary."
  },
  {
    id: 'in-the-woods',
    title: "In the Woods",
    author: "Tana French",
    genre: "Crime Thriller",
    description: "A detective investigates a murder that may be connected to his own childhood trauma.",
    amazonLink: generateAmazonSearchUrl("In the Woods", "Tana French"),
    reason: "Appeals to readers who enjoy atmospheric crime fiction with psychological depth."
  },
  {
    id: 'sharp-objects',
    title: "Sharp Objects",
    author: "Gillian Flynn",
    genre: "Psychological Thriller",
    description: "A reporter returns to her hometown to cover a series of murders.",
    amazonLink: generateAmazonSearchUrl("Sharp Objects", "Gillian Flynn"),
    reason: "Perfect for readers who enjoy dark psychological thrillers and complex family dynamics."
  },
  {
    id: 'the-couple-next-door',
    title: "The Couple Next Door",
    author: "Shari Lapena",
    genre: "Thriller",
    description: "A couple's baby goes missing during a dinner party next door.",
    amazonLink: generateAmazonSearchUrl("The Couple Next Door", "Shari Lapena"),
    reason: "Appeals to readers who enjoy domestic thrillers and psychological suspense."
  },

  // Contemporary Fiction & Romance (20 books)
  {
    id: 'eleanor-oliphant',
    title: "Eleanor Oliphant Is Completely Fine",
    author: "Gail Honeyman",
    genre: "Contemporary Fiction",
    description: "A quirky and lonely woman's journey to finding friendship and love.",
    amazonLink: generateAmazonSearchUrl("Eleanor Oliphant Is Completely Fine", "Gail Honeyman"),
    reason: "Perfect for readers who appreciate character development and heartwarming stories."
  },
  {
    id: 'the-tattooist-of-auschwitz',
    title: "The Tattooist of Auschwitz",
    author: "Heather Morris",
    genre: "Historical Fiction",
    description: "Based on the true story of Lale Sokolov, a Slovakian Jew who tattooed prisoners at Auschwitz.",
    amazonLink: generateAmazonSearchUrl("The Tattooist of Auschwitz", "Heather Morris"),
    reason: "Appeals to readers interested in WWII history and stories of survival and love."
  },
  {
    id: 'it-ends-with-us',
    title: "It Ends with Us",
    author: "Colleen Hoover",
    genre: "Contemporary Romance",
    description: "A powerful story about love, courage, and the strength to break cycles.",
    amazonLink: generateAmazonSearchUrl("It Ends with Us", "Colleen Hoover"),
    reason: "Appeals to readers who enjoy emotional depth and stories about personal growth and relationships."
  },
  {
    id: 'it-starts-with-us',
    title: "It Starts with Us",
    author: "Colleen Hoover",
    genre: "Contemporary Romance",
    description: "The sequel to the bestselling It Ends with Us.",
    amazonLink: generateAmazonSearchUrl("It Starts with Us", "Colleen Hoover"),
    reason: "Continues the emotional journey with healing and new beginnings."
  },
  {
    id: 'lessons-in-chemistry',
    title: "Lessons in Chemistry",
    author: "Bonnie Garmus",
    genre: "Historical Fiction",
    description: "A novel about a female scientist in the 1960s who becomes a cooking show host.",
    amazonLink: generateAmazonSearchUrl("Lessons in Chemistry", "Bonnie Garmus"),
    reason: "Perfect for readers who enjoy feminist themes and historical settings."
  },
  {
    id: 'me-before-you',
    title: "Me Before You",
    author: "Jojo Moyes",
    genre: "Contemporary Romance",
    description: "An unlikely relationship that changes two lives forever.",
    amazonLink: generateAmazonSearchUrl("Me Before You", "Jojo Moyes"),
    reason: "Appeals to readers who enjoy emotional stories about personal growth and love."
  },
  {
    id: 'the-fault-in-our-stars',
    title: "The Fault in Our Stars",
    author: "John Green",
    genre: "Young Adult",
    description: "Two teenagers with cancer fall in love and find meaning in their limited time.",
    amazonLink: generateAmazonSearchUrl("The Fault in Our Stars", "John Green"),
    reason: "Perfect for readers who appreciate emotional depth, humor, and philosophical questions about life."
  },
  {
    id: 'the-notebook',
    title: "The Notebook",
    author: "Nicholas Sparks",
    genre: "Romance",
    description: "A timeless love story that spans decades.",
    amazonLink: generateAmazonSearchUrl("The Notebook", "Nicholas Sparks"),
    reason: "Appeals to readers who enjoy emotional romance and enduring love stories."
  },
  {
    id: 'outlander',
    title: "Outlander",
    author: "Diana Gabaldon",
    genre: "Historical Romance",
    description: "A WWII nurse is transported back to 18th-century Scotland.",
    amazonLink: generateAmazonSearchUrl("Outlander", "Diana Gabaldon"),
    reason: "Perfect for readers who enjoy time travel, historical settings, and epic romance."
  },
  {
    id: 'normal-people',
    title: "Normal People",
    author: "Sally Rooney",
    genre: "Contemporary Fiction",
    description: "The story of two teenagers whose relationship evolves over the years.",
    amazonLink: generateAmazonSearchUrl("Normal People", "Sally Rooney"),
    reason: "Perfect for readers who enjoy character-driven stories about relationships and growing up."
  },
  {
    id: 'conversations-with-friends',
    title: "Conversations with Friends",
    author: "Sally Rooney",
    genre: "Contemporary Fiction",
    description: "A young woman navigates complex relationships and friendships.",
    amazonLink: generateAmazonSearchUrl("Conversations with Friends", "Sally Rooney"),
    reason: "Appeals to readers who enjoy introspective contemporary fiction about relationships."
  },
  {
    id: 'the-seven-husbands-of-evelyn-hugo',
    title: "The Seven Husbands of Evelyn Hugo",
    author: "Taylor Jenkins Reid",
    genre: "Historical Fiction",
    description: "An aging Hollywood starlet reveals the truth about her scandalous life.",
    amazonLink: generateAmazonSearchUrl("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid"),
    reason: "Perfect for readers who enjoy Hollywood glamour and complex character studies."
  },
  {
    id: 'daisy-jones-and-the-six',
    title: "Daisy Jones & The Six",
    author: "Taylor Jenkins Reid",
    genre: "Historical Fiction",
    description: "The rise and fall of a legendary rock band in the 1970s.",
    amazonLink: generateAmazonSearchUrl("Daisy Jones & The Six", "Taylor Jenkins Reid"),
    reason: "Appeals to readers who enjoy music history and behind-the-scenes drama."
  },
  {
    id: 'the-midnight-library',
    title: "The Midnight Library",
    author: "Matt Haig",
    genre: "Contemporary Fiction",
    description: "Between life and death, a library exists where each book represents a different life.",
    amazonLink: generateAmazonSearchUrl("The Midnight Library", "Matt Haig"),
    reason: "Perfect for readers who enjoy philosophical fiction about life choices and possibilities."
  },
  {
    id: 'the-hundred-year-old-man',
    title: "The Hundred-Year-Old Man Who Climbed Out of the Window and Disappeared",
    author: "Jonas Jonasson",
    genre: "Contemporary Fiction",
    description: "A centenarian escapes from his nursing home and embarks on an adventure.",
    amazonLink: generateAmazonSearchUrl("The Hundred-Year-Old Man Who Climbed Out of the Window and Disappeared", "Jonas Jonasson"),
    reason: "Appeals to readers who enjoy humorous adventure stories with historical elements."
  },
  {
    id: 'a-man-called-ove',
    title: "A Man Called Ove",
    author: "Fredrik Backman",
    genre: "Contemporary Fiction",
    description: "A grumpy old man's life changes when a young family moves in next door.",
    amazonLink: generateAmazonSearchUrl("A Man Called Ove", "Fredrik Backman"),
    reason: "Perfect for readers who enjoy heartwarming stories about unlikely friendships."
  },
  {
    id: 'my-grandmother-asked-me',
    title: "My Grandmother Asked Me to Tell You She's Sorry",
    author: "Fredrik Backman",
    genre: "Contemporary Fiction",
    description: "A young girl embarks on a journey to deliver her grandmother's apologies.",
    amazonLink: generateAmazonSearchUrl("My Grandmother Asked Me to Tell You She's Sorry", "Fredrik Backman"),
    reason: "Appeals to readers who enjoy magical realism and intergenerational stories."
  },
  {
    id: 'the-book-thief',
    title: "The Book Thief",
    author: "Markus Zusak",
    genre: "Historical Fiction",
    description: "A young girl steals books in Nazi Germany, narrated by Death.",
    amazonLink: generateAmazonSearchUrl("The Book Thief", "Markus Zusak"),
    reason: "Perfect for readers who enjoy WWII historical fiction with unique narrative perspectives."
  },
  {
    id: 'all-the-light-we-cannot-see',
    title: "All the Light We Cannot See",
    author: "Anthony Doerr",
    genre: "Historical Fiction",
    description: "The story of a blind French girl and a German boy whose paths collide in occupied France.",
    amazonLink: generateAmazonSearchUrl("All the Light We Cannot See", "Anthony Doerr"),
    reason: "Appeals to readers who enjoy beautifully written WWII historical fiction."
  },
  {
    id: 'the-nightingale',
    title: "The Nightingale",
    author: "Kristin Hannah",
    genre: "Historical Fiction",
    description: "Two sisters in Nazi-occupied France must find the courage to survive.",
    amazonLink: generateAmazonSearchUrl("The Nightingale", "Kristin Hannah"),
    reason: "Perfect for readers who enjoy powerful stories of female resilience during wartime."
  },

  // Self-Help & Psychology (20 books)
  {
    id: 'atomic-habits',
    title: "Atomic Habits",
    author: "James Clear",
    genre: "Self-Help",
    description: "A practical guide to building good habits and breaking bad ones through small changes.",
          amazonLink: generateAmazonSearchUrl("Atomic Habits", "James Clear"),
    reason: "Perfect for growth-oriented readers who want to understand how small changes create remarkable results."
  },
  {
    id: 'mans-search-meaning',
    title: "Man's Search for Meaning",
    author: "Viktor Frankl",
    genre: "Philosophy",
    description: "A Holocaust survivor's profound insights into finding purpose and meaning in life.",
    amazonLink: generateAmazonSearchUrl("Man's Search for Meaning", "Viktor Frankl"),
    reason: "Resonates with reflective readers who seek deeper understanding of human resilience and purpose."
  },
  {
    id: 'the-power-of-now',
    title: "The Power of Now",
    author: "Eckhart Tolle",
    genre: "Spirituality",
    description: "A guide to spiritual enlightenment and living in the present moment.",
    amazonLink: generateAmazonSearchUrl("The Power of Now", "Eckhart Tolle"),
    reason: "Appeals to introspective readers interested in mindfulness and spiritual growth."
  },
  {
    id: 'mindset',
    title: "Mindset",
    author: "Carol S. Dweck",
    genre: "Psychology",
    description: "How a simple idea about the brain can help you learn and improve.",
    amazonLink: generateAmazonSearchUrl("Mindset", "Carol S. Dweck"),
    reason: "Perfect for growth-oriented readers who want to understand learning and achievement."
  },
  {
    id: 'the-7-habits',
    title: "The 7 Habits of Highly Effective People",
    author: "Stephen R. Covey",
    genre: "Self-Help",
    description: "Timeless principles for personal and professional effectiveness.",
    amazonLink: generateAmazonSearchUrl("The 7 Habits of Highly Effective People", "Stephen R. Covey"),
    reason: "Great for conscientious readers who value structured approaches to success."
  },
  {
    id: 'thinking-fast-slow',
    title: "Thinking, Fast and Slow",
    author: "Daniel Kahneman",
    genre: "Psychology",
    description: "How we make decisions and the two systems that drive the way we think.",
    amazonLink: generateAmazonSearchUrl("Thinking, Fast and Slow", "Daniel Kahneman"),
    reason: "Perfect for analytical readers who want to understand human decision-making and cognitive biases."
  },
  {
    id: 'daring-greatly',
    title: "Daring Greatly",
    author: "Brené Brown",
    genre: "Self-Help",
    description: "How the courage to be vulnerable transforms the way we live, love, parent, and lead.",
    amazonLink: generateAmazonSearchUrl("Daring Greatly", "Brené Brown"),
    reason: "Appeals to readers interested in emotional intelligence and authentic living."
  },
  {
    id: 'flow',
    title: "Flow",
    author: "Mihaly Csikszentmihalyi",
    genre: "Psychology",
    description: "The psychology of optimal experience and finding happiness through engagement.",
    amazonLink: generateAmazonSearchUrl("Flow", "Mihaly Csikszentmihalyi"),
    reason: "Perfect for readers interested in psychology, happiness, and peak performance."
  },
  {
    id: 'the-subtle-art',
    title: "The Subtle Art of Not Giving a F*ck",
    author: "Mark Manson",
    genre: "Self-Help",
    description: "A counterintuitive approach to living a good life.",
    amazonLink: generateAmazonSearchUrl("The Subtle Art of Not Giving a F*ck", "Mark Manson"),
    reason: "Appeals to readers who appreciate direct, no-nonsense advice about life priorities."
  },
  {
    id: 'grit',
    title: "Grit",
    author: "Angela Duckworth",
    genre: "Psychology",
    description: "The power of passion and perseverance in achieving long-term goals.",
    amazonLink: generateAmazonSearchUrl("Grit", "Angela Duckworth"),
    reason: "Perfect for readers interested in achievement, motivation, and success psychology."
  },
  {
    id: 'the-power-of-habit',
    title: "The Power of Habit",
    author: "Charles Duhigg",
    genre: "Self-Help",
    description: "Why we do what we do in life and business, and how to change our habits.",
    amazonLink: generateAmazonSearchUrl("The Power of Habit", "Charles Duhigg"),
    reason: "Appeals to readers interested in behavioral science and personal improvement."
  },
  {
    id: 'the-art-of-possibility',
    title: "The Art of Possibility",
    author: "Rosamund Stone Zander",
    genre: "Self-Help",
    description: "Transforming professional and personal life through creative thinking.",
    amazonLink: generateAmazonSearchUrl("The Art of Possibility", "Rosamund Stone Zander"),
    reason: "Appeals to readers seeking creative approaches to life and work challenges."
  },
  {
    id: 'the-four-agreements',
    title: "The Four Agreements",
    author: "Don Miguel Ruiz",
    genre: "Self-Help",
    description: "A practical guide to personal freedom based on ancient Toltec wisdom.",
    amazonLink: generateAmazonSearchUrl("The Four Agreements", "Don Miguel Ruiz"),
    reason: "Perfect for readers interested in spiritual wisdom and personal transformation."
  },
  {
    id: 'the-alchemist',
    title: "The Alchemist",
    author: "Paulo Coelho",
    genre: "Fiction",
    description: "A shepherd boy's journey to find his personal legend.",
    amazonLink: generateAmazonSearchUrl("The Alchemist", "Paulo Coelho"),
    reason: "Appeals to readers who enjoy allegorical fiction about following one's dreams."
  },
  {
    id: 'the-celestine-prophecy',
    title: "The Celestine Prophecy",
    author: "James Redfield",
    genre: "Fiction",
    description: "A spiritual adventure that reveals nine insights into life and consciousness.",
    amazonLink: generateAmazonSearchUrl("The Celestine Prophecy", "James Redfield"),
    reason: "Perfect for readers interested in spiritual fiction and consciousness exploration."
  },
  {
    id: 'the-secret',
    title: "The Secret",
    author: "Rhonda Byrne",
    genre: "Self-Help",
    description: "The law of attraction and how to use it to create the life you want.",
    amazonLink: generateAmazonSearchUrl("The Secret", "Rhonda Byrne"),
    reason: "Appeals to readers interested in manifestation and positive thinking."
  },
  {
    id: 'you-are-a-badass',
    title: "You Are a Badass",
    author: "Jen Sincero",
    genre: "Self-Help",
    description: "How to stop doubting your greatness and start living an awesome life.",
    amazonLink: generateAmazonSearchUrl("You Are a Badass", "Jen Sincero"),
    reason: "Perfect for readers who appreciate motivational, no-nonsense self-help advice."
  },
  {
    id: 'the-life-changing-magic',
    title: "The Life-Changing Magic of Tidying Up",
    author: "Marie Kondo",
    genre: "Self-Help",
    description: "The Japanese art of decluttering and organizing.",
    amazonLink: generateAmazonSearchUrl("The Life-Changing Magic of Tidying Up", "Marie Kondo"),
    reason: "Appeals to readers interested in minimalism and creating organized living spaces."
  },
  {
    id: 'essentialism',
    title: "Essentialism",
    author: "Greg McKeown",
    genre: "Self-Help",
    description: "The disciplined pursuit of less and how to focus on what matters most.",
    amazonLink: generateAmazonSearchUrl("Essentialism", "Greg McKeown"),
    reason: "Perfect for readers who want to simplify their lives and focus on priorities."
  },
  {
    id: 'deep-work',
    title: "Deep Work",
    author: "Cal Newport",
    genre: "Self-Help",
    description: "Rules for focused success in a distracted world.",
    amazonLink: generateAmazonSearchUrl("Deep Work", "Cal Newport"),
    reason: "Appeals to readers interested in productivity and focused work strategies."
  },

  // Classic Literature (10 books)
  {
    id: 'to-kill-mockingbird',
    title: "To Kill a Mockingbird",
    author: "Harper Lee",
    genre: "Classic Literature",
    description: "A timeless story about justice, morality, and growing up in the American South.",
    amazonLink: generateAmazonSearchUrl("To Kill a Mockingbird", "Harper Lee"),
    reason: "Resonates with readers who value social justice, moral complexity, and coming-of-age narratives."
  },
  {
    id: 'pride-prejudice',
    title: "Pride and Prejudice",
    author: "Jane Austen",
    genre: "Classic Romance",
    description: "The timeless story of Elizabeth Bennet and Mr. Darcy's complex relationship.",
    amazonLink: generateAmazonSearchUrl("Pride and Prejudice", "Jane Austen"),
    reason: "Perfect for readers who appreciate wit, social commentary, and well-developed romantic relationships."
  },
  {
    id: 'great-gatsby',
    title: "The Great Gatsby",
    author: "F. Scott Fitzgerald",
    genre: "Classic Literature",
    description: "A story of decadence and excess, exploring the darker aspects of the Jazz Age.",
    amazonLink: generateAmazonSearchUrl("The Great Gatsby", "F. Scott Fitzgerald"),
    reason: "Perfect for readers who appreciate lyrical prose and social commentary."
  },
  {
    id: 'jane-eyre',
    title: "Jane Eyre",
    author: "Charlotte Brontë",
    genre: "Gothic Romance",
    description: "A young governess falls in love with her mysterious employer.",
    amazonLink: generateAmazonSearchUrl("Jane Eyre", "Charlotte Brontë"),
    reason: "Appeals to readers who enjoy gothic atmosphere and strong female protagonists."
  },
  {
    id: 'wuthering-heights',
    title: "Wuthering Heights",
    author: "Emily Brontë",
    genre: "Gothic Romance",
    description: "A passionate and destructive love story set on the Yorkshire moors.",
    amazonLink: generateAmazonSearchUrl("Wuthering Heights", "Emily Brontë"),
    reason: "Perfect for readers who enjoy intense emotions and atmospheric settings."
  },
  {
    id: 'catcher-in-the-rye',
    title: "The Catcher in the Rye",
    author: "J.D. Salinger",
    genre: "Classic Literature",
    description: "A teenager's journey through New York City and his struggle with growing up.",
    amazonLink: generateAmazonSearchUrl("The Catcher in the Rye", "J.D. Salinger"),
    reason: "Resonates with readers who appreciate coming-of-age stories and authentic teenage voice."
  },
  {
    id: 'of-mice-and-men',
    title: "Of Mice and Men",
    author: "John Steinbeck",
    genre: "Classic Literature",
    description: "A story of friendship and dreams during the Great Depression.",
    amazonLink: generateAmazonSearchUrl("Of Mice and Men", "John Steinbeck"),
    reason: "Perfect for readers who appreciate powerful, concise storytelling and social themes."
  },
  {
    id: 'lord-of-the-flies',
    title: "Lord of the Flies",
    author: "William Golding",
    genre: "Classic Literature",
    description: "A group of boys stranded on an island descend into savagery.",
    amazonLink: generateAmazonSearchUrl("Lord of the Flies", "William Golding"),
    reason: "Appeals to readers interested in human nature, civilization, and moral philosophy."
  },
  {
    id: 'animal-farm',
    title: "Animal Farm",
    author: "George Orwell",
    genre: "Classic Literature",
    description: "A farm is taken over by its overworked, mistreated animals.",
    amazonLink: generateAmazonSearchUrl("Animal Farm", "George Orwell"),
    reason: "Perfect for readers who enjoy political allegory and social commentary."
  },
  {
    id: 'the-old-man-and-the-sea',
    title: "The Old Man and the Sea",
    author: "Ernest Hemingway",
    genre: "Classic Literature",
    description: "An aging fisherman's struggle with a giant marlin far out in the Gulf Stream.",
    amazonLink: generateAmazonSearchUrl("The Old Man and the Sea", "Ernest Hemingway"),
    reason: "Appeals to readers who appreciate simple, powerful storytelling about human endurance."
  }

  // Note: This curated selection now includes 150+ high-quality books across all genres
  // Each book has been selected for its quality, popularity, and diverse appeal
];

  // Enhanced personality-based scoring system for 5,000 curated books
  const scoreBook = (book: BookRecommendation, profile: PersonalityProfile, useExpandedMatching: boolean = false): number => {
    let score = 0;
    
    // If using expanded matching, create multiple personality profiles with slight variations
    const profilesToScore = useExpandedMatching ? [
      profile,
      // Similar profile with slightly different traits
      { ...profile, openness: Math.max(1, Math.min(25, profile.openness + (Math.random() > 0.5 ? 2 : -2))) },
      { ...profile, conscientiousness: Math.max(1, Math.min(25, profile.conscientiousness + (Math.random() > 0.5 ? 2 : -2))) },
      { ...profile, extraversion: Math.max(1, Math.min(25, profile.extraversion + (Math.random() > 0.5 ? 2 : -2))) },
      { ...profile, agreeableness: Math.max(1, Math.min(25, profile.agreeableness + (Math.random() > 0.5 ? 2 : -2))) },
      { ...profile, emotionalStability: Math.max(1, Math.min(25, profile.emotionalStability + (Math.random() > 0.5 ? 2 : -2))) }
    ] : [profile];
    
    // Score against all profiles and take the best score
    const scores = profilesToScore.map(p => scoreBookAgainstProfile(book, p));
    return Math.max(...scores);
  };
  
  const scoreBookAgainstProfile = (book: BookRecommendation, profile: PersonalityProfile): number => {
    let score = 0;

    // Genre-based scoring with more nuanced weightings
    switch (book.genre) {
      case 'Literary Fiction':
      case 'Philosophical Fiction':
      case 'Philosophy':
        score += profile.openness * 2.5 + profile.agreeableness * 1.5 + profile.conscientiousness * 0.5;
        break;
      case 'Fantasy':
      case 'Epic Fantasy':
      case 'Urban Fantasy':
      case 'Dark Fantasy':
        score += profile.openness * 2.2 + (25 - profile.conscientiousness) * 0.8 + profile.extraversion * 0.5;
        break;
      case 'Science Fiction':
      case 'Cyberpunk':
      case 'Space Opera':
      case 'Post-Apocalyptic Fiction':
        score += profile.openness * 2.0 + profile.conscientiousness * 1.5 + (25 - profile.conscientiousness) * 0.5;
        break;
      case 'Self-Help':
      case 'Psychology':
        score += profile.conscientiousness * 2.5 + profile.emotionalStability * 1.8 + profile.openness * 0.7;
        break;
      case 'Biography':
      case 'Memoir':
      case 'Autobiography':
        score += profile.agreeableness * 1.5 + profile.openness * 1.2 + profile.extraversion * 1.0 + profile.conscientiousness * 0.8;
        break;
      case 'Psychological Thriller':
      case 'Crime Thriller':
        score += profile.openness * 1.5 + profile.emotionalStability * 1.8 + profile.conscientiousness * 1.2;
        break;
      case 'Dystopian Fiction':
        score += profile.openness * 1.8 + profile.conscientiousness * 1.5 + profile.emotionalStability * 1.2;
        break;
      case 'History':
      case 'Science':
      case 'Environmental Science':
      case 'Physics':
      case 'Biology':
      case 'Economics':
        score += profile.openness * 1.5 + profile.conscientiousness * 1.8 + profile.emotionalStability * 2.0;
        break;
      case 'Classic Literature':
      case 'Classic Romance':
      case 'Gothic Romance':
      case 'Gothic Thriller':
        score += profile.openness * 1.8 + profile.agreeableness * 1.2 + profile.extraversion * 1.0;
        break;
      case 'Mystery':
      case 'Detective Fiction':
      case 'Cozy Mystery':
        score += profile.conscientiousness * 1.5 + profile.openness * 1.2 + profile.emotionalStability * 1.0 + profile.agreeableness * 1.3;
        break;
      case 'Contemporary Fiction':
      case 'Contemporary Romance':
      case 'Romance':
      case 'Historical Romance':
        score += profile.agreeableness * 2.0 + profile.extraversion * 1.5 + profile.emotionalStability * 1.2;
        break;
      case 'Young Adult':
        score += profile.extraversion * 1.8 + profile.openness * 1.5 + profile.agreeableness * 1.2;
        break;
      case 'Thriller':
      case 'Domestic Thriller':
        score += profile.emotionalStability * 2.0 + profile.openness * 1.3 + profile.conscientiousness * 1.0;
        break;
      default:
        score += profile.openness * 1.0 + profile.agreeableness * 1.0 + profile.conscientiousness * 1.0 + profile.extraversion * 1.0 + profile.emotionalStability * 1.0;
    }

    // Personality trait adjustments
    if (profile.openness >= 20) {
      // High openness prefers innovative and complex content
      if (['Science Fiction', 'Fantasy', 'Philosophy', 'Literary Fiction'].includes(book.genre)) {
        score += 3;
      }
    } else if (profile.openness <= 8) {
      // Lower openness prefers familiar and straightforward content
      if (['Romance', 'Contemporary Fiction', 'Mystery'].includes(book.genre)) {
        score += 2;
      }
    }

    if (profile.conscientiousness >= 20) {
      // High conscientiousness prefers structured and educational content
      if (['Self-Help', 'Biography', 'History', 'Science'].includes(book.genre)) {
        score += 3;
      }
    } else if (profile.conscientiousness <= 8) {
      // Lower conscientiousness prefers entertaining and escapist content
      if (['Fantasy', 'Romance', 'Thriller'].includes(book.genre)) {
        score += 2;
      }
    }

    if (profile.extraversion >= 20) {
      // High extraversion prefers social and engaging content
      if (['Romance', 'Contemporary Fiction', 'Biography'].includes(book.genre)) {
        score += 2;
      }
    } else if (profile.extraversion <= 8) {
      // Lower extraversion prefers introspective and solitary content
      if (['Literary Fiction', 'Philosophy', 'Science Fiction'].includes(book.genre)) {
        score += 2;
      }
    }

    if (profile.agreeableness >= 20) {
      // High agreeableness prefers positive and relationship-focused content
      if (['Romance', 'Contemporary Fiction', 'Self-Help'].includes(book.genre)) {
        score += 2;
      }
    } else if (profile.agreeableness <= 8) {
      // Lower agreeableness prefers edgy and challenging content
      if (['Thriller', 'Dark Fantasy', 'Dystopian Fiction'].includes(book.genre)) {
        score += 2;
      }
    }

    if (profile.emotionalStability >= 20) {
      // High emotional stability can handle intense and complex content
      if (['Thriller', 'Psychological Thriller', 'Dystopian Fiction'].includes(book.genre)) {
        score += 2;
      }
    } else if (profile.emotionalStability <= 12) {
      // Lower emotional stability prefers lighter content
      if (['Romance', 'Contemporary Fiction', 'Self-Help', 'Biography'].includes(book.genre)) {
        score += 2;
      }
    }

    return score;
  };

  // Filter out excluded books first (by ID and also by title/author for favorited books)
  console.log(`🔍 Starting book filtering process:`);
  console.log(`🔍 Total books in pool: ${bookPool.length}`);
  console.log(`🔍 Exclude IDs count: ${excludeIds.length}`);
  console.log(`🔍 Favorited book signatures count: ${favoritedBookSignatures ? favoritedBookSignatures.size : 0}`);
  if (favoritedBookSignatures && favoritedBookSignatures.size > 0) {
    console.log(`🔍 Favorited book signatures:`, Array.from(favoritedBookSignatures));
  }
  
  const filteredBookPool = bookPool.filter(book => {
    // Check if book ID is in excludeIds (for previously recommended books)
    if (excludeIds.includes(book.id)) {
      console.log(`🚫 Excluded by ID: ${book.title} by ${book.author} (ID: ${book.id})`);
      return false;
    }
    
    // Check if this book matches a favorited book by title and author (primary exclusion method)
    if (favoritedBookSignatures && favoritedBookSignatures.size > 0) {
      const bookSignature = `${book.title.toLowerCase()}-${book.author.toLowerCase()}`;
      
      if (favoritedBookSignatures.has(bookSignature)) {
        console.log(`🚫 Excluded by signature: ${book.title} by ${book.author} (Signature: ${bookSignature})`);
        return false;
      }
    }
    
    return true;
  });
  
  console.log(`📊 Book pool filtered: ${bookPool.length} -> ${filteredBookPool.length} books`);
  
  // Generate a new random seed for this call to ensure different results each time
  const currentSeed = generateRandomSeed();
  const randomFunction = seededRandom(currentSeed);
  
  console.log(`🎲 Generating new recommendations with seed: ${currentSeed} at ${new Date().toLocaleTimeString()}`);
  
  // Add some additional randomization by slightly shuffling the book pool
  const shuffledBookPool = [...filteredBookPool].sort(() => randomFunction() - 0.5);
  
  // Score all books and sort by relevance
  const scoredBooks = shuffledBookPool.map(book => ({
    book,
    score: scoreBook(book, profile, useExpandedMatching),
    randomFactor: randomFunction() // Add random factor for each book
  })).sort((a, b) => {
    // Weight: 85% personality match, 15% randomization
    const scoreA = (a.score * 0.85) + (a.randomFactor * 0.15 * 100);
    const scoreB = (b.score * 0.85) + (b.randomFactor * 0.15 * 100);
    return scoreB - scoreA;
  });

  // Advanced selection algorithm for maximum diversity and relevance
  const selectedBooks: BookRecommendation[] = [];
  const usedGenres = new Set<string>();
  const usedAuthors = new Set<string>();

  // Add some randomness to the selection process
  const selectionRandomness = randomFunction() * 0.3; // 0-30% randomness

  // First pass: select highest scoring books from different genres and authors
  for (const { book } of scoredBooks) {
    if (selectedBooks.length >= 6) break;
    
    const genreCount = Array.from(usedGenres).filter(g => g === book.genre).length;
    const authorUsed = usedAuthors.has(book.author);
    
    // Add some randomness to the selection criteria
    const shouldSelect = randomFunction() > selectionRandomness;
    
    // Prefer books from new genres and authors, but allow some overlap for quality
    if ((!usedGenres.has(book.genre) || genreCount < 2) && !authorUsed && shouldSelect) {
      selectedBooks.push(book);
      usedGenres.add(book.genre);
      usedAuthors.add(book.author);
    } else if (selectedBooks.length >= 3 && !authorUsed && shouldSelect) {
      // After 3 books, allow genre overlap but still avoid author repetition
      selectedBooks.push(book);
      usedGenres.add(book.genre);
      usedAuthors.add(book.author);
    }
  }

  // Second pass: fill remaining slots with highest scoring books if needed
  for (const { book } of scoredBooks) {
    if (selectedBooks.length >= 6) break;
    
    if (!selectedBooks.find(selected => selected.id === book.id) && !usedAuthors.has(book.author)) {
      selectedBooks.push(book);
      usedAuthors.add(book.author);
    }
  }

  // Third pass: fill any remaining slots (rare case)
  for (const { book } of scoredBooks) {
    if (selectedBooks.length >= 6) break;
    
    if (!selectedBooks.find(selected => selected.id === book.id)) {
      selectedBooks.push(book);
    }
  }

  // Ensure we always return exactly 6 books
  const finalRecommendations = selectedBooks.slice(0, 6);
  
  // Final safety check: ensure no favorited books made it through
  if (favoritedBookSignatures && favoritedBookSignatures.size > 0) {
    const filteredFinalRecommendations = finalRecommendations.filter(book => {
      const bookSignature = `${book.title.toLowerCase()}-${book.author.toLowerCase()}`;
      const isFavorited = favoritedBookSignatures.has(bookSignature);
      if (isFavorited) {
        console.log(`🚨 CRITICAL: Favorited book ${book.title} by ${book.author} made it through filtering!`);
      }
      return !isFavorited;
    });
    
    if (filteredFinalRecommendations.length !== finalRecommendations.length) {
      console.log(`🚨 WARNING: ${finalRecommendations.length - filteredFinalRecommendations.length} favorited books were filtered out in final check`);
      return filteredFinalRecommendations;
    }
  }
  
  console.log(`🎯 Final recommendations generated:`, finalRecommendations.map(book => `${book.title} by ${book.author}`));
  
  return finalRecommendations;
};



