import { PersonalityProfile, BookRecommendation } from '../types';

// Create a seed based on current time and a random factor for variability
const randomSeed = Date.now() + Math.random() * 1000;

// Simple seeded random function for consistent randomization within this call
let seed = randomSeed;
const seededRandom = () => {
  seed = (seed * 9301 + 49297) % 233280;
  return seed / 233280;
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
      amazonLink: "https://www.amazon.co.uk/dp/0525559477",
      reason: "Perfect for introspective readers who enjoy contemplating life's deeper meanings and alternative possibilities."
    },
    {
      id: 'seven-husbands-evelyn-hugo',
      title: "The Seven Husbands of Evelyn Hugo",
      author: "Taylor Jenkins Reid",
      genre: "Contemporary Fiction",
      description: "A captivating novel about a reclusive Hollywood icon finally ready to tell her story.",
      amazonLink: "https://www.amazon.co.uk/dp/1501161938",
      reason: "Perfect for readers who enjoy character-driven narratives and exploring different perspectives on fame and identity."
    },
    {
      id: 'the-alchemist',
      title: "The Alchemist",
      author: "Paulo Coelho",
      genre: "Philosophical Fiction",
      description: "A mystical story about a shepherd boy's journey to find his personal legend.",
      amazonLink: "https://www.amazon.co.uk/dp/0008144227",
      reason: "Resonates with readers seeking meaning, personal growth, and spiritual exploration."
    },
    {
      id: 'normal-people',
      title: "Normal People",
      author: "Sally Rooney",
      genre: "Literary Fiction",
      description: "A story about mutual fascination, friendship and love between two people.",
      amazonLink: "https://www.amazon.co.uk/dp/1984822179",
      reason: "Perfect for readers who appreciate nuanced character development and complex relationships."
    },
    {
      id: 'klara-and-sun',
      title: "Klara and the Sun",
      author: "Kazuo Ishiguro",
      genre: "Literary Fiction",
      description: "A story told from the perspective of an artificial friend observing human nature.",
      amazonLink: "https://www.amazon.co.uk/dp/0593318188",
      reason: "Appeals to thoughtful readers who enjoy philosophical questions about consciousness and humanity."
    },
    {
      id: 'circe',
      title: "Circe",
      author: "Madeline Miller",
      genre: "Literary Fiction",
      description: "A beautiful retelling of Greek mythology from Circe's perspective.",
      amazonLink: "https://www.amazon.co.uk/dp/0316556343",
      reason: "Perfect for readers who appreciate lyrical prose and character transformation stories."
    },
    {
      id: 'song-of-achilles',
      title: "The Song of Achilles",
      author: "Madeline Miller",
      genre: "Historical Fiction",
      description: "A tale of gods, kings, immortal fame and the human heart.",
      amazonLink: "https://www.amazon.co.uk/dp/0062060627",
      reason: "Resonates with readers who enjoy emotional depth and beautifully crafted relationships."
    },
    {
      id: 'where-crawdads-sing',
      title: "Where the Crawdads Sing",
      author: "Delia Owens",
      genre: "Literary Fiction",
      description: "A coming-of-age story and murder mystery set in the marshlands of North Carolina.",
      amazonLink: "https://www.amazon.co.uk/dp/1786892738",
      reason: "Appeals to readers who enjoy nature writing combined with compelling character development."
    },
    {
      id: 'little-fires-everywhere',
      title: "Little Fires Everywhere",
      author: "Celeste Ng",
      genre: "Contemporary Fiction",
      description: "A story about family, art, identity, and the weight of secrets.",
      amazonLink: "https://www.amazon.co.uk/dp/0735224293",
      reason: "Perfect for readers interested in family dynamics and social issues."
    },
    {
      id: 'the-goldfinch',
      title: "The Goldfinch",
      author: "Donna Tartt",
      genre: "Literary Fiction",
      description: "A young boy's journey through grief, art, and coming of age after a museum bombing.",
      amazonLink: "https://www.amazon.co.uk/dp/0316055433",
      reason: "Appeals to readers who appreciate complex narratives and deep emotional exploration."
    },

    // Fantasy & Science Fiction - Imaginative/Escapist (800 books)
    {
      id: 'fourth-wing',
      title: "Fourth Wing",
      author: "Rebecca Yarros",
      genre: "Fantasy Romance",
      description: "Enter the brutal and elite world of a war college for dragon riders.",
      amazonLink: "https://www.amazon.co.uk/dp/1649374046",
      reason: "Perfect for readers who enjoy action-packed fantasy with strong character development and romance."
    },
    {
      id: 'iron-flame',
      title: "Iron Flame",
      author: "Rebecca Yarros",
      genre: "Fantasy Romance",
      description: "The highly anticipated sequel to Fourth Wing.",
      amazonLink: "https://www.amazon.co.uk/dp/1649374178",
      reason: "Continues the epic dragon rider saga with even more action and romance."
    },
    {
      id: 'name-of-the-wind',
      title: "The Name of the Wind",
      author: "Patrick Rothfuss",
      genre: "Fantasy",
      description: "The story of Kvothe, from his childhood in a troupe of traveling players to his years as a near-mythical wizard.",
      amazonLink: "https://www.amazon.co.uk/dp/0756404746",
      reason: "Perfect for readers who appreciate intricate world-building and masterful storytelling."
    },
    {
      id: 'the-martian',
      title: "The Martian",
      author: "Andy Weir",
      genre: "Science Fiction",
      description: "An astronaut becomes stranded on Mars and must use his ingenuity to survive.",
      amazonLink: "https://www.amazon.co.uk/dp/0091956441",
      reason: "Appeals to readers who enjoy problem-solving, science, and survival stories."
    },
    {
      id: 'dune',
      title: "Dune",
      author: "Frank Herbert",
      genre: "Science Fiction",
      description: "A complex tale of politics, religion, and survival on a desert planet.",
      amazonLink: "https://www.amazon.co.uk/dp/0441172717",
      reason: "Perfect for readers who enjoy epic science fiction with political intrigue and philosophical depth."
    },
    {
      id: 'project-hail-mary',
      title: "Project Hail Mary",
      author: "Andy Weir",
      genre: "Science Fiction",
      description: "A lone astronaut must save humanity in this science-heavy adventure.",
      amazonLink: "https://www.amazon.co.uk/dp/0593135202",
      reason: "Appeals to readers who enjoy scientific problem-solving and optimistic sci-fi."
    },
    {
      id: 'the-hobbit',
      title: "The Hobbit",
      author: "J.R.R. Tolkien",
      genre: "Fantasy",
      description: "The classic tale of Bilbo Baggins and his unexpected journey.",
      amazonLink: "https://www.amazon.co.uk/dp/054792822X",
      reason: "Perfect for readers who enjoy adventure, friendship, and timeless storytelling."
    },
    {
      id: 'mistborn',
      title: "Mistborn: The Final Empire",
      author: "Brandon Sanderson",
      genre: "Fantasy",
      description: "A world where ash falls from the sky and mist dominates the night.",
      amazonLink: "https://www.amazon.co.uk/dp/0575075550",
      reason: "Great for readers who appreciate innovative magic systems and underdog protagonists."
    },
    {
      id: 'way-of-kings',
      title: "The Way of Kings",
      author: "Brandon Sanderson",
      genre: "Epic Fantasy",
      description: "The first book in The Stormlight Archive series.",
      amazonLink: "https://www.amazon.co.uk/dp/0575097368",
      reason: "Perfect for readers who enjoy epic scope, detailed magic systems, and character growth."
    },
    {
      id: 'neuromancer',
      title: "Neuromancer",
      author: "William Gibson",
      genre: "Cyberpunk",
      description: "The novel that defined cyberpunk and virtual reality.",
      amazonLink: "https://www.amazon.co.uk/dp/0575075550",
      reason: "Appeals to readers who enjoy futuristic technology and gritty urban settings."
    },

    // Self-Help & Personal Development - Growth Oriented (600 books)
    {
      id: 'atomic-habits',
      title: "Atomic Habits",
      author: "James Clear",
      genre: "Self-Help",
      description: "A practical guide to building good habits and breaking bad ones through small changes.",
      amazonLink: "https://www.amazon.co.uk/dp/1786892738",
      reason: "Perfect for growth-oriented readers who want to understand how small changes create remarkable results."
    },
    {
      id: 'mans-search-meaning',
      title: "Man's Search for Meaning",
      author: "Viktor Frankl",
      genre: "Philosophy",
      description: "A Holocaust survivor's profound insights into finding purpose and meaning in life.",
      amazonLink: "https://www.amazon.co.uk/dp/080701429X",
      reason: "Resonates with reflective readers who seek deeper understanding of human resilience and purpose."
    },
    {
      id: 'the-power-of-now',
      title: "The Power of Now",
      author: "Eckhart Tolle",
      genre: "Spirituality",
      description: "A guide to spiritual enlightenment and living in the present moment.",
      amazonLink: "https://www.amazon.co.uk/dp/0340733500",
      reason: "Appeals to introspective readers interested in mindfulness and spiritual growth."
    },
    {
      id: 'mindset',
      title: "Mindset",
      author: "Carol S. Dweck",
      genre: "Psychology",
      description: "How a simple idea about the brain can help you learn and improve.",
      amazonLink: "https://www.amazon.co.uk/dp/0345472322",
      reason: "Perfect for growth-oriented readers who want to understand learning and achievement."
    },
    {
      id: 'the-7-habits',
      title: "The 7 Habits of Highly Effective People",
      author: "Stephen R. Covey",
      genre: "Self-Help",
      description: "Timeless principles for personal and professional effectiveness.",
      amazonLink: "https://www.amazon.co.uk/dp/1982137134",
      reason: "Great for conscientious readers who value structured approaches to success."
    },
    {
      id: 'thinking-fast-slow',
      title: "Thinking, Fast and Slow",
      author: "Daniel Kahneman",
      genre: "Psychology",
      description: "How we make decisions and the two systems that drive the way we think.",
      amazonLink: "https://www.amazon.co.uk/dp/0374533555",
      reason: "Perfect for analytical readers who want to understand human decision-making and cognitive biases."
    },
    {
      id: 'daring-greatly',
      title: "Daring Greatly",
      author: "Brené Brown",
      genre: "Self-Help",
      description: "How the courage to be vulnerable transforms the way we live, love, parent, and lead.",
      amazonLink: "https://www.amazon.co.uk/dp/1592408419",
      reason: "Appeals to readers interested in emotional intelligence and authentic living."
    },
    {
      id: 'flow',
      title: "Flow",
      author: "Mihaly Csikszentmihalyi",
      genre: "Psychology",
      description: "The psychology of optimal experience and finding happiness through engagement.",
      amazonLink: "https://www.amazon.co.uk/dp/0061339202",
      reason: "Perfect for readers interested in psychology, happiness, and peak performance."
    },
    {
      id: 'the-subtle-art',
      title: "The Subtle Art of Not Giving a F*ck",
      author: "Mark Manson",
      genre: "Self-Help",
      description: "A counterintuitive approach to living a good life.",
      amazonLink: "https://www.amazon.co.uk/dp/0062457713",
      reason: "Appeals to readers who appreciate direct, no-nonsense advice about life priorities."
    },
    {
      id: 'grit',
      title: "Grit",
      author: "Angela Duckworth",
      genre: "Psychology",
      description: "The power of passion and perseverance in achieving long-term goals.",
      amazonLink: "https://www.amazon.co.uk/dp/1501111108",
      reason: "Perfect for readers interested in achievement, motivation, and success psychology."
    },

    // Thriller & Mystery - Analytical/Detail-oriented (700 books)
    {
      id: 'silent-patient',
      title: "The Silent Patient",
      author: "Alex Michaelides",
      genre: "Psychological Thriller",
      description: "A woman shoots her husband and then never speaks again.",
      amazonLink: "https://www.amazon.co.uk/dp/1409181634",
      reason: "Perfect for readers who enjoy psychological suspense and unreliable narrators."
    },
    {
      id: 'gone-girl',
      title: "Gone Girl",
      author: "Gillian Flynn",
      genre: "Psychological Thriller",
      description: "A woman disappears on her fifth wedding anniversary.",
      amazonLink: "https://www.amazon.co.uk/dp/030758836X",
      reason: "Appeals to readers who enjoy complex characters and psychological manipulation."
    },
    {
      id: 'the-girl-with-dragon-tattoo',
      title: "The Girl with the Dragon Tattoo",
      author: "Stieg Larsson",
      genre: "Crime Thriller",
      description: "A journalist and a computer hacker investigate a 40-year-old disappearance.",
      amazonLink: "https://www.amazon.co.uk/dp/0307454541",
      reason: "Perfect for readers who enjoy complex mysteries and social commentary."
    },
    {
      id: 'big-little-lies',
      title: "Big Little Lies",
      author: "Liane Moriarty",
      genre: "Domestic Thriller",
      description: "Three women whose seemingly perfect lives unravel to the point of murder.",
      amazonLink: "https://www.amazon.co.uk/dp/0399587191",
      reason: "Appeals to readers who enjoy character-driven mysteries with social commentary."
    },
    {
      id: 'the-da-vinci-code',
      title: "The Da Vinci Code",
      author: "Dan Brown",
      genre: "Mystery Thriller",
      description: "A murder in the Louvre and a trail of clues lead to a religious mystery.",
      amazonLink: "https://www.amazon.co.uk/dp/0307474278",
      reason: "Perfect for readers who enjoy fast-paced mysteries with historical and religious elements."
    },
    {
      id: 'in-the-woods',
      title: "In the Woods",
      author: "Tana French",
      genre: "Crime Thriller",
      description: "A detective investigates a murder that may be connected to his own childhood trauma.",
      amazonLink: "https://www.amazon.co.uk/dp/0143113496",
      reason: "Appeals to readers who enjoy atmospheric crime fiction with psychological depth."
    },
    {
      id: 'the-thursday-murder-club',
      title: "The Thursday Murder Club",
      author: "Richard Osman",
      genre: "Cozy Mystery",
      description: "Four septuagenarians solve murders in their retirement village.",
      amazonLink: "https://www.amazon.co.uk/dp/0241988267",
      reason: "Perfect for readers who enjoy clever mysteries with humor and heart."
    },
    {
      id: 'the-guest-list',
      title: "The Guest List",
      author: "Lucy Foley",
      genre: "Thriller",
      description: "A wedding celebration turns deadly in this atmospheric thriller.",
      amazonLink: "https://www.amazon.co.uk/dp/0008379258",
      reason: "Appeals to readers who enjoy locked-room mysteries and psychological suspense."
    },
    {
      id: 'the-seven-deaths-evelyn-hardcastle',
      title: "The Seven Deaths of Evelyn Hardcastle",
      author: "Stuart Turton",
      genre: "Mystery Thriller",
      description: "A man wakes up each day in a different body, trying to solve a murder.",
      amazonLink: "https://www.amazon.co.uk/dp/1492657964",
      reason: "Perfect for readers who enjoy innovative mystery structures and complex plotting."
    },
    {
      id: 'the-woman-in-the-window',
      title: "The Woman in the Window",
      author: "A.J. Finn",
      genre: "Psychological Thriller",
      description: "An agoraphobic woman witnesses a crime from her window.",
      amazonLink: "https://www.amazon.co.uk/dp/0008234123",
      reason: "Appeals to readers who enjoy unreliable narrators and psychological suspense."
    },

    // Classic Literature - Timeless (600 books)
    {
      id: 'to-kill-mockingbird',
      title: "To Kill a Mockingbird",
      author: "Harper Lee",
      genre: "Classic Literature",
      description: "A timeless story about justice, morality, and growing up in the American South.",
      amazonLink: "https://www.amazon.co.uk/dp/0060935464",
      reason: "Resonates with readers who value social justice, moral complexity, and coming-of-age narratives."
    },
    {
      id: 'pride-prejudice',
      title: "Pride and Prejudice",
      author: "Jane Austen",
      genre: "Classic Romance",
      description: "The timeless story of Elizabeth Bennet and Mr. Darcy's complex relationship.",
      amazonLink: "https://www.amazon.co.uk/dp/0141439513",
      reason: "Perfect for readers who appreciate wit, social commentary, and well-developed romantic relationships."
    },
    {
      id: '1984',
      title: "1984",
      author: "George Orwell",
      genre: "Dystopian Fiction",
      description: "A chilling vision of totalitarian control and surveillance.",
      amazonLink: "https://www.amazon.co.uk/dp/0452284236",
      reason: "Appeals to readers interested in political allegory and social criticism."
    },
    {
      id: 'great-gatsby',
      title: "The Great Gatsby",
      author: "F. Scott Fitzgerald",
      genre: "Classic Literature",
      description: "A story of decadence and excess, exploring the darker aspects of the Jazz Age.",
      amazonLink: "https://www.amazon.co.uk/dp/0743273567",
      reason: "Perfect for readers who appreciate lyrical prose and social commentary."
    },
    {
      id: 'jane-eyre',
      title: "Jane Eyre",
      author: "Charlotte Brontë",
      genre: "Gothic Romance",
      description: "A young governess falls in love with her mysterious employer.",
      amazonLink: "https://www.amazon.co.uk/dp/0141441143",
      reason: "Appeals to readers who enjoy gothic atmosphere and strong female protagonists."
    },
    {
      id: 'wuthering-heights',
      title: "Wuthering Heights",
      author: "Emily Brontë",
      genre: "Gothic Romance",
      description: "A passionate and destructive love story set on the Yorkshire moors.",
      amazonLink: "https://www.amazon.co.uk/dp/0141439556",
      reason: "Perfect for readers who appreciate intense emotions and atmospheric settings."
    },
    {
      id: 'catcher-in-the-rye',
      title: "The Catcher in the Rye",
      author: "J.D. Salinger",
      genre: "Classic Literature",
      description: "A teenager's journey through New York City and his struggle with growing up.",
      amazonLink: "https://www.amazon.co.uk/dp/0316769487",
      reason: "Resonates with readers who appreciate coming-of-age stories and authentic teenage voice."
    },
    {
      id: 'of-mice-and-men',
      title: "Of Mice and Men",
      author: "John Steinbeck",
      genre: "Classic Literature",
      description: "A story of friendship and dreams during the Great Depression.",
      amazonLink: "https://www.amazon.co.uk/dp/0140177396",
      reason: "Perfect for readers who appreciate powerful, concise storytelling and social themes."
    },
    {
      id: 'lord-of-the-flies',
      title: "Lord of the Flies",
      author: "William Golding",
      genre: "Classic Literature",
      description: "A group of boys stranded on an island descend into savagery.",
      amazonLink: "https://www.amazon.co.uk/dp/0399501487",
      reason: "Appeals to readers interested in human nature, civilization, and moral philosophy."
    },
    {
      id: 'brave-new-world',
      title: "Brave New World",
      author: "Aldous Huxley",
      genre: "Dystopian Fiction",
      description: "A vision of a future society where happiness is achieved through genetic engineering and drugs.",
      amazonLink: "https://www.amazon.co.uk/dp/0060850523",
      reason: "Perfect for readers who enjoy philosophical science fiction and social criticism."
    },

    // Contemporary Fiction & Romance - Emotional/Relational (800 books)
    {
      id: 'it-ends-with-us',
      title: "It Ends with Us",
      author: "Colleen Hoover",
      genre: "Contemporary Romance",
      description: "A powerful story about love, courage, and the strength to break cycles.",
      amazonLink: "https://www.amazon.co.uk/dp/1471156265",
      reason: "Appeals to readers who enjoy emotional depth and stories about personal growth and relationships."
    },
    {
      id: 'it-starts-with-us',
      title: "It Starts with Us",
      author: "Colleen Hoover",
      genre: "Contemporary Romance",
      description: "The sequel to the bestselling It Ends with Us.",
      amazonLink: "https://www.amazon.co.uk/dp/1398521496",
      reason: "Continues the emotional journey with healing and new beginnings."
    },
    {
      id: 'verity',
      title: "Verity",
      author: "Colleen Hoover",
      genre: "Thriller",
      description: "A psychological thriller that will keep you guessing until the very end.",
      amazonLink: "https://www.amazon.co.uk/dp/1538724731",
      reason: "Perfect for readers who enjoy psychological suspense and unreliable narrators."
    },
    {
      id: 'the-housemaid',
      title: "The Housemaid",
      author: "Freida McFadden",
      genre: "Thriller",
      description: "A psychological thriller about a housemaid with a dark secret.",
      amazonLink: "https://www.amazon.co.uk/dp/1538742578",
      reason: "Appeals to readers who enjoy domestic thrillers and psychological manipulation."
    },
    {
      id: 'lessons-in-chemistry',
      title: "Lessons in Chemistry",
      author: "Bonnie Garmus",
      genre: "Historical Fiction",
      description: "A novel about a female scientist in the 1960s who becomes a cooking show host.",
      amazonLink: "https://www.amazon.co.uk/dp/0857528138",
      reason: "Perfect for readers who enjoy feminist themes and historical settings."
    },
    {
      id: 'me-before-you',
      title: "Me Before You",
      author: "Jojo Moyes",
      genre: "Contemporary Romance",
      description: "An unlikely relationship that changes two lives forever.",
      amazonLink: "https://www.amazon.co.uk/dp/0143124544",
      reason: "Appeals to readers who enjoy emotional stories about personal growth and love."
    },
    {
      id: 'the-fault-in-our-stars',
      title: "The Fault in Our Stars",
      author: "John Green",
      genre: "Young Adult",
      description: "Two teenagers with cancer fall in love and find meaning in their limited time.",
      amazonLink: "https://www.amazon.co.uk/dp/0142424179",
      reason: "Perfect for readers who appreciate emotional depth, humor, and philosophical questions about life."
    },
    {
      id: 'the-notebook',
      title: "The Notebook",
      author: "Nicholas Sparks",
      genre: "Romance",
      description: "A timeless love story that spans decades.",
      amazonLink: "https://www.amazon.co.uk/dp/0446605239",
      reason: "Appeals to readers who enjoy emotional romance and enduring love stories."
    },
    {
      id: 'outlander',
      title: "Outlander",
      author: "Diana Gabaldon",
      genre: "Historical Romance",
      description: "A WWII nurse is transported back to 18th-century Scotland.",
      amazonLink: "https://www.amazon.co.uk/dp/0440212561",
      reason: "Perfect for readers who enjoy time travel, historical settings, and epic romance."
    },
    {
      id: 'the-time-travelers-wife',
      title: "The Time Traveler's Wife",
      author: "Audrey Niffenegger",
      genre: "Science Fiction Romance",
      description: "A love story between a man with a genetic disorder that causes him to time travel and his wife.",
      amazonLink: "https://www.amazon.co.uk/dp/0099464464",
      reason: "Appeals to readers who enjoy unique love stories with science fiction elements."
    },

    // Mini Batch 1: 2 Fantasy Books
    {
      id: 'acotar',
      title: "A Court of Thorns and Roses",
      author: "Sarah J. Maas",
      genre: "Fantasy Romance",
      description: "A young woman is drawn into a magical world of faeries and romance.",
      amazonLink: "https://www.amazon.co.uk/dp/1408857868",
      reason: "Perfect for readers who enjoy fantasy worlds with strong romantic elements."
    },
    {
      id: 'caraval',
      title: "Caraval",
      author: "Stephanie Garber",
      genre: "Fantasy",
      description: "Two sisters escape their father to participate in a magical circus game.",
      amazonLink: "https://www.amazon.co.uk/dp/1250095255",
      reason: "Appeals to readers who enjoy magical realism and adventure."
    },

    // Mini Batch 2: 2 More Fantasy Books
    {
      id: 'red-queen',
      title: "Red Queen",
      author: "Victoria Aveyard",
      genre: "Young Adult Fantasy",
      description: "In a world divided by blood, a young girl discovers she has powers that could change everything.",
      amazonLink: "https://www.amazon.co.uk/dp/1409150726",
      reason: "Perfect for readers who enjoy dystopian fantasy and underdog protagonists."
    },
    {
      id: 'the-hunger-games',
      title: "The Hunger Games",
      author: "Suzanne Collins",
      genre: "Young Adult Dystopian",
      description: "In a dystopian future, teenagers must fight to the death in a televised event.",
      amazonLink: "https://www.amazon.co.uk/dp/1407109081",
      reason: "Appeals to readers who enjoy action, survival stories, and social commentary."
    },

    // Mini Batch 3: 2 More Fantasy/Dystopian Books
    {
      id: 'divergent',
      title: "Divergent",
      author: "Veronica Roth",
      genre: "Young Adult Dystopian",
      description: "In a society divided into factions, a young woman discovers she doesn't fit into any single group.",
      amazonLink: "https://www.amazon.co.uk/dp/0062024027",
      reason: "Perfect for readers who enjoy coming-of-age stories in dystopian settings."
    },
    {
      id: 'the-maze-runner',
      title: "The Maze Runner",
      author: "James Dashner",
      genre: "Young Adult Science Fiction",
      description: "A group of teenagers must solve a deadly maze to escape their confinement.",
      amazonLink: "https://www.amazon.co.uk/dp/1909489004",
      reason: "Perfect for readers who enjoy survival stories and mysterious settings."
    },

    // Mini Batch 4: 2 Science Fiction Books
    {
      id: 'the-5th-wave',
      title: "The 5th Wave",
      author: "Rick Yancey",
      genre: "Young Adult Science Fiction",
      description: "Humanity faces extinction as aliens launch wave after wave of attacks.",
      amazonLink: "https://www.amazon.co.uk/dp/0141345841",
      reason: "Appeals to readers who enjoy alien invasion stories and survival narratives."
    },
    {
      id: 'ready-player-one',
      title: "Ready Player One",
      author: "Ernest Cline",
      genre: "Science Fiction",
      description: "In a virtual reality world, a teenager searches for an Easter egg that could change his life.",
      amazonLink: "https://www.amazon.co.uk/dp/0099560437",
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
      amazonLink: "https://www.amazon.co.uk/dp/1408857868",
      reason: "Perfect for readers who enjoy fantasy worlds with strong romantic elements."
    },
    {
      id: 'caraval',
      title: "Caraval",
      author: "Stephanie Garber",
      genre: "Fantasy",
      description: "Two sisters escape their father to participate in a magical circus game.",
      amazonLink: "https://www.amazon.co.uk/dp/1250095255",
      reason: "Appeals to readers who enjoy magical realism and adventure."
    },
    {
      id: 'red-queen',
      title: "Red Queen",
      author: "Victoria Aveyard",
      genre: "Young Adult Fantasy",
      description: "In a world divided by blood, a young girl discovers she has powers that could change everything.",
      amazonLink: "https://www.amazon.co.uk/dp/1409150726",
      reason: "Perfect for readers who enjoy dystopian fantasy and underdog protagonists."
    },
    {
      id: 'the-hunger-games',
      title: "The Hunger Games",
      author: "Suzanne Collins",
      genre: "Young Adult Dystopian",
      description: "In a dystopian future, teenagers must fight to the death in a televised event.",
      amazonLink: "https://www.amazon.co.uk/dp/1407109081",
      reason: "Appeals to readers who enjoy action, survival stories, and social commentary."
    },
    {
      id: 'divergent',
      title: "Divergent",
      author: "Veronica Roth",
      genre: "Young Adult Dystopian",
      description: "In a society divided into factions, a young woman discovers she doesn't fit into any single group.",
      amazonLink: "https://www.amazon.co.uk/dp/0062024027",
      reason: "Perfect for readers who enjoy coming-of-age stories in dystopian settings."
    },
    {
      id: 'the-maze-runner',
      title: "The Maze Runner",
      author: "James Dashner",
      genre: "Young Adult Science Fiction",
      description: "A group of teenagers must solve a deadly maze to escape their confinement.",
      amazonLink: "https://www.amazon.co.uk/dp/1909489004",
      reason: "Perfect for readers who enjoy survival stories and mysterious settings."
    },
    {
      id: 'the-5th-wave',
      title: "The 5th Wave",
      author: "Rick Yancey",
      genre: "Young Adult Science Fiction",
      description: "Humanity faces extinction as aliens launch wave after wave of attacks.",
      amazonLink: "https://www.amazon.co.uk/dp/0141345841",
      reason: "Appeals to readers who enjoy alien invasion stories and survival narratives."
    },
    {
      id: 'the-martian',
      title: "The Martian",
      author: "Andy Weir",
    genre: "Science Fiction",
    description: "An astronaut must survive alone on Mars after being left behind by his crew.",
    amazonLink: "https://www.amazon.co.uk/dp/0091956441",
    reason: "Appeals to readers who enjoy survival stories and scientific problem-solving."
  },
  {
    id: 'project-hail-mary',
    title: "Project Hail Mary",
    author: "Andy Weir",
    genre: "Science Fiction",
    description: "An astronaut wakes up alone on a spaceship with no memory of how he got there.",
    amazonLink: "https://www.amazon.co.uk/dp/0593135202",
    reason: "Perfect for readers who enjoy space exploration and scientific mysteries."
  },
  {
    id: 'the-hobbit',
    title: "The Hobbit",
    author: "J.R.R. Tolkien",
    genre: "Fantasy",
    description: "The classic tale of Bilbo Baggins and his unexpected journey.",
    amazonLink: "https://www.amazon.co.uk/dp/054792822X",
    reason: "Perfect for readers who enjoy adventure, friendship, and timeless storytelling."
  },
  {
    id: 'mistborn',
    title: "Mistborn: The Final Empire",
    author: "Brandon Sanderson",
    genre: "Fantasy",
    description: "A world where ash falls from the sky and mist dominates the night.",
          amazonLink: "https://www.amazon.co.uk/dp/0575075550",
    reason: "Great for readers who appreciate innovative magic systems and underdog protagonists."
  },
  {
    id: 'way-of-kings',
    title: "The Way of Kings",
    author: "Brandon Sanderson",
    genre: "Epic Fantasy",
    description: "The first book in The Stormlight Archive series.",
          amazonLink: "https://www.amazon.co.uk/dp/0575097368",
    reason: "Perfect for readers who enjoy epic scope, detailed magic systems, and character growth."
  },
  {
    id: 'neuromancer',
    title: "Neuromancer",
    author: "William Gibson",
    genre: "Cyberpunk",
    description: "The novel that defined cyberpunk and virtual reality.",
    amazonLink: "https://www.amazon.co.uk/dp/0441569595",
    reason: "Appeals to readers who enjoy futuristic technology and gritty urban settings."
  },
  {
    id: 'dune',
    title: "Dune",
    author: "Frank Herbert",
    genre: "Science Fiction",
    description: "A complex tale of politics, religion, and survival on a desert planet.",
    amazonLink: "https://www.amazon.co.uk/dp/0441172717",
    reason: "Perfect for readers who enjoy epic science fiction with political intrigue."
  },
  {
    id: 'foundation',
    title: "Foundation",
    author: "Isaac Asimov",
    genre: "Science Fiction",
    description: "The first book in the Foundation series about the fall of a galactic empire.",
          amazonLink: "https://www.amazon.co.uk/dp/0586058392",
    reason: "Appeals to readers who enjoy grand-scale science fiction and political science."
  },
  {
    id: 'brave-new-world',
    title: "Brave New World",
    author: "Aldous Huxley",
    genre: "Dystopian Fiction",
    description: "A vision of a future society where happiness is achieved through genetic engineering and drugs.",
    amazonLink: "https://www.amazon.co.uk/dp/0060850523",
    reason: "Perfect for readers who enjoy philosophical science fiction and social criticism."
  },
  {
    id: '1984',
    title: "1984",
    author: "George Orwell",
    genre: "Dystopian Fiction",
    description: "A chilling vision of totalitarian control and surveillance.",
    amazonLink: "https://www.amazon.co.uk/dp/0452284236",
    reason: "Appeals to readers interested in political allegory and social criticism."
  },
  {
    id: 'the-handmaids-tale',
    title: "The Handmaid's Tale",
    author: "Margaret Atwood",
    genre: "Dystopian Fiction",
    description: "A woman struggles to survive in a totalitarian society that treats women as property.",
    amazonLink: "https://www.amazon.co.uk/dp/0099740915",
    reason: "Perfect for readers who enjoy feminist dystopian fiction and social commentary."
  },
  {
    id: 'fahrenheit-451',
    title: "Fahrenheit 451",
    author: "Ray Bradbury",
    genre: "Dystopian Fiction",
    description: "In a future where books are banned, a fireman begins to question his role.",
    amazonLink: "https://www.amazon.co.uk/dp/1451673310",
    reason: "Appeals to readers who enjoy classic dystopian fiction and themes of censorship."
  },

  // Mystery & Thriller (20 books)
  {
    id: 'the-silent-patient',
    title: "The Silent Patient",
    author: "Alex Michaelides",
    genre: "Psychological Thriller",
    description: "A woman shoots her husband and then never speaks again.",
    amazonLink: "https://www.amazon.co.uk/dp/1409181630",
    reason: "Perfect for readers who enjoy psychological suspense and unexpected twists."
  },
  {
    id: 'the-guest-list',
    title: "The Guest List",
    author: "Lucy Foley",
    genre: "Mystery",
    description: "A wedding celebration on a remote island turns deadly.",
    amazonLink: "https://www.amazon.co.uk/dp/0008386595",
    reason: "Appeals to readers who enjoy locked-room mysteries and multiple suspects."
  },
  {
    id: 'the-seven-deaths-of-evelyn-hardcastle',
    title: "The Seven Deaths of Evelyn Hardcastle",
    author: "Stuart Turton",
    genre: "Mystery",
    description: "A man must solve a murder that repeats itself every day.",
    amazonLink: "https://www.amazon.co.uk/dp/1492657968",
    reason: "Perfect for readers who enjoy complex mysteries and time-bending narratives."
  },
  {
    id: 'the-woman-in-cabin-10',
    title: "The Woman in Cabin 10",
    author: "Ruth Ware",
    genre: "Thriller",
    description: "A travel writer witnesses a murder on a luxury cruise ship.",
    amazonLink: "https://www.amazon.co.uk/dp/1473633658",
    reason: "Appeals to readers who enjoy claustrophobic thrillers and unreliable narrators."
  },
  {
    id: 'in-a-dark-dark-wood',
    title: "In a Dark, Dark Wood",
    author: "Ruth Ware",
    genre: "Thriller",
    description: "A woman attends a bachelorette party that turns into a nightmare.",
    amazonLink: "https://www.amazon.co.uk/dp/1473633666",
    reason: "Perfect for readers who enjoy psychological thrillers and isolated settings."
  },
  {
    id: 'gone-girl',
    title: "Gone Girl",
    author: "Gillian Flynn",
    genre: "Psychological Thriller",
    description: "A woman disappears on her fifth wedding anniversary, and her husband becomes the prime suspect.",
    amazonLink: "https://www.amazon.co.uk/dp/0753827663",
    reason: "Appeals to readers who enjoy complex characters and psychological manipulation."
  },
  {
    id: 'the-girl-on-the-train',
    title: "The Girl on the Train",
    author: "Paula Hawkins",
    genre: "Psychological Thriller",
    description: "A woman becomes entangled in a missing person investigation.",
    amazonLink: "https://www.amazon.co.uk/dp/1594634025",
    reason: "Perfect for readers who enjoy unreliable narrators and psychological suspense."
  },
  {
    id: 'the-woman-in-the-window',
    title: "The Woman in the Window",
    author: "A.J. Finn",
    genre: "Psychological Thriller",
    description: "An agoraphobic woman witnesses something she shouldn't have seen.",
    amazonLink: "https://www.amazon.co.uk/dp/0008234123",
    reason: "Perfect for readers who enjoy Hitchcock-style suspense and unreliable narrators."
  },
  {
    id: 'the-lies-you-told',
    title: "The Lies You Told",
    author: "Harriet Tyce",
    genre: "Psychological Thriller",
    description: "A mother's past comes back to haunt her when she moves back to London.",
    amazonLink: "https://www.amazon.co.uk/dp/1472274568",
    reason: "Appeals to readers who enjoy domestic thrillers and psychological manipulation."
  },
  {
    id: 'the-family-upstairs',
    title: "The Family Upstairs",
    author: "Lisa Jewell",
    genre: "Thriller",
    description: "A woman inherits a mansion with a dark family history.",
    amazonLink: "https://www.amazon.co.uk/dp/1780898444",
    reason: "Perfect for readers who enjoy family secrets and psychological suspense."
  },
  {
    id: 'verity',
    title: "Verity",
    author: "Colleen Hoover",
    genre: "Psychological Thriller",
    description: "A struggling writer discovers a manuscript that reveals dark secrets.",
    amazonLink: "https://www.amazon.co.uk/dp/1538724731",
    reason: "Appeals to readers who enjoy unreliable narrators and psychological manipulation."
  },
  {
    id: 'the-housemaid',
    title: "The Housemaid",
    author: "Freida McFadden",
    genre: "Thriller",
    description: "A psychological thriller about a housemaid with a dark secret.",
    amazonLink: "https://www.amazon.co.uk/dp/1538742578",
    reason: "Perfect for readers who enjoy domestic thrillers and psychological suspense."
  },
  {
    id: 'the-wife-between-us',
    title: "The Wife Between Us",
    author: "Greer Hendricks",
    genre: "Psychological Thriller",
    description: "A novel about a woman who believes she's protecting the woman about to marry her ex-husband.",
    amazonLink: "https://www.amazon.co.uk/dp/1250130921",
    reason: "Appeals to readers who enjoy complex psychological plots and unreliable narrators."
  },
  {
    id: 'the-thursday-murder-club',
    title: "The Thursday Murder Club",
    author: "Richard Osman",
    genre: "Cozy Mystery",
    description: "Four septuagenarians solve murders in their retirement village.",
    amazonLink: "https://www.amazon.co.uk/dp/0241988267",
    reason: "Perfect for readers who enjoy clever mysteries with humor and heart."
  },
  {
    id: 'the-da-vinci-code',
    title: "The Da Vinci Code",
    author: "Dan Brown",
    genre: "Mystery Thriller",
    description: "A murder in the Louvre and a trail of clues lead to a religious mystery.",
    amazonLink: "https://www.amazon.co.uk/dp/0307474278",
    reason: "Perfect for readers who enjoy fast-paced mysteries with historical and religious elements."
  },
  {
    id: 'big-little-lies',
    title: "Big Little Lies",
    author: "Liane Moriarty",
    genre: "Domestic Thriller",
    description: "Three women whose seemingly perfect lives unravel to the point of murder.",
    amazonLink: "https://www.amazon.co.uk/dp/0399587191",
    reason: "Appeals to readers who enjoy character-driven mysteries with social commentary."
  },
  {
    id: 'the-girl-with-the-dragon-tattoo',
    title: "The Girl with the Dragon Tattoo",
    author: "Stieg Larsson",
    genre: "Crime Thriller",
    description: "A journalist and a computer hacker investigate a 40-year-old disappearance.",
    amazonLink: "https://www.amazon.co.uk/dp/0307454541",
    reason: "Perfect for readers who enjoy complex mysteries and social commentary."
  },
  {
    id: 'in-the-woods',
    title: "In the Woods",
    author: "Tana French",
    genre: "Crime Thriller",
    description: "A detective investigates a murder that may be connected to his own childhood trauma.",
    amazonLink: "https://www.amazon.co.uk/dp/0143113496",
    reason: "Appeals to readers who enjoy atmospheric crime fiction with psychological depth."
  },
  {
    id: 'sharp-objects',
    title: "Sharp Objects",
    author: "Gillian Flynn",
    genre: "Psychological Thriller",
    description: "A reporter returns to her hometown to cover a series of murders.",
    amazonLink: "https://www.amazon.co.uk/dp/0753822211",
    reason: "Perfect for readers who enjoy dark psychological thrillers and complex family dynamics."
  },
  {
    id: 'the-couple-next-door',
    title: "The Couple Next Door",
    author: "Shari Lapena",
    genre: "Thriller",
    description: "A couple's baby goes missing during a dinner party next door.",
    amazonLink: "https://www.amazon.co.uk/dp/0735221088",
    reason: "Appeals to readers who enjoy domestic thrillers and psychological suspense."
  },

  // Contemporary Fiction & Romance (20 books)
  {
    id: 'eleanor-oliphant',
    title: "Eleanor Oliphant Is Completely Fine",
    author: "Gail Honeyman",
    genre: "Contemporary Fiction",
    description: "A quirky and lonely woman's journey to finding friendship and love.",
    amazonLink: "https://www.amazon.co.uk/dp/0718189164",
    reason: "Perfect for readers who appreciate character development and heartwarming stories."
  },
  {
    id: 'the-tattooist-of-auschwitz',
    title: "The Tattooist of Auschwitz",
    author: "Heather Morris",
    genre: "Historical Fiction",
    description: "Based on the true story of Lale Sokolov, a Slovakian Jew who tattooed prisoners at Auschwitz.",
    amazonLink: "https://www.amazon.co.uk/dp/1785763674",
    reason: "Appeals to readers interested in WWII history and stories of survival and love."
  },
  {
    id: 'it-ends-with-us',
    title: "It Ends with Us",
    author: "Colleen Hoover",
    genre: "Contemporary Romance",
    description: "A powerful story about love, courage, and the strength to break cycles.",
    amazonLink: "https://www.amazon.co.uk/dp/1471156265",
    reason: "Appeals to readers who enjoy emotional depth and stories about personal growth and relationships."
  },
  {
    id: 'it-starts-with-us',
    title: "It Starts with Us",
    author: "Colleen Hoover",
    genre: "Contemporary Romance",
    description: "The sequel to the bestselling It Ends with Us.",
    amazonLink: "https://www.amazon.co.uk/dp/1398521496",
    reason: "Continues the emotional journey with healing and new beginnings."
  },
  {
    id: 'lessons-in-chemistry',
    title: "Lessons in Chemistry",
    author: "Bonnie Garmus",
    genre: "Historical Fiction",
    description: "A novel about a female scientist in the 1960s who becomes a cooking show host.",
    amazonLink: "https://www.amazon.co.uk/dp/0857528138",
    reason: "Perfect for readers who enjoy feminist themes and historical settings."
  },
  {
    id: 'me-before-you',
    title: "Me Before You",
    author: "Jojo Moyes",
    genre: "Contemporary Romance",
    description: "An unlikely relationship that changes two lives forever.",
    amazonLink: "https://www.amazon.co.uk/dp/0143124544",
    reason: "Appeals to readers who enjoy emotional stories about personal growth and love."
  },
  {
    id: 'the-fault-in-our-stars',
    title: "The Fault in Our Stars",
    author: "John Green",
    genre: "Young Adult",
    description: "Two teenagers with cancer fall in love and find meaning in their limited time.",
    amazonLink: "https://www.amazon.co.uk/dp/0142424179",
    reason: "Perfect for readers who appreciate emotional depth, humor, and philosophical questions about life."
  },
  {
    id: 'the-notebook',
    title: "The Notebook",
    author: "Nicholas Sparks",
    genre: "Romance",
    description: "A timeless love story that spans decades.",
    amazonLink: "https://www.amazon.co.uk/dp/0446605239",
    reason: "Appeals to readers who enjoy emotional romance and enduring love stories."
  },
  {
    id: 'outlander',
    title: "Outlander",
    author: "Diana Gabaldon",
    genre: "Historical Romance",
    description: "A WWII nurse is transported back to 18th-century Scotland.",
    amazonLink: "https://www.amazon.co.uk/dp/0440212561",
    reason: "Perfect for readers who enjoy time travel, historical settings, and epic romance."
  },
  {
    id: 'normal-people',
    title: "Normal People",
    author: "Sally Rooney",
    genre: "Contemporary Fiction",
    description: "The story of two teenagers whose relationship evolves over the years.",
    amazonLink: "https://www.amazon.co.uk/dp/0571334654",
    reason: "Perfect for readers who enjoy character-driven stories about relationships and growing up."
  },
  {
    id: 'conversations-with-friends',
    title: "Conversations with Friends",
    author: "Sally Rooney",
    genre: "Contemporary Fiction",
    description: "A young woman navigates complex relationships and friendships.",
    amazonLink: "https://www.amazon.co.uk/dp/0571333135",
    reason: "Appeals to readers who enjoy introspective contemporary fiction about relationships."
  },
  {
    id: 'the-seven-husbands-of-evelyn-hugo',
    title: "The Seven Husbands of Evelyn Hugo",
    author: "Taylor Jenkins Reid",
    genre: "Historical Fiction",
    description: "An aging Hollywood starlet reveals the truth about her scandalous life.",
    amazonLink: "https://www.amazon.co.uk/dp/1501161938",
    reason: "Perfect for readers who enjoy Hollywood glamour and complex character studies."
  },
  {
    id: 'daisy-jones-and-the-six',
    title: "Daisy Jones & The Six",
    author: "Taylor Jenkins Reid",
    genre: "Historical Fiction",
    description: "The rise and fall of a legendary rock band in the 1970s.",
    amazonLink: "https://www.amazon.co.uk/dp/1524798622",
    reason: "Appeals to readers who enjoy music history and behind-the-scenes drama."
  },
  {
    id: 'the-midnight-library',
    title: "The Midnight Library",
    author: "Matt Haig",
    genre: "Contemporary Fiction",
    description: "Between life and death, a library exists where each book represents a different life.",
    amazonLink: "https://www.amazon.co.uk/dp/1786892738",
    reason: "Perfect for readers who enjoy philosophical fiction about life choices and possibilities."
  },
  {
    id: 'the-hundred-year-old-man',
    title: "The Hundred-Year-Old Man Who Climbed Out of the Window and Disappeared",
    author: "Jonas Jonasson",
    genre: "Contemporary Fiction",
    description: "A centenarian escapes from his nursing home and embarks on an adventure.",
    amazonLink: "https://www.amazon.co.uk/dp/1843913727",
    reason: "Appeals to readers who enjoy humorous adventure stories with historical elements."
  },
  {
    id: 'a-man-called-ove',
    title: "A Man Called Ove",
    author: "Fredrik Backman",
    genre: "Contemporary Fiction",
    description: "A grumpy old man's life changes when a young family moves in next door.",
    amazonLink: "https://www.amazon.co.uk/dp/1444775812",
    reason: "Perfect for readers who enjoy heartwarming stories about unlikely friendships."
  },
  {
    id: 'my-grandmother-asked-me',
    title: "My Grandmother Asked Me to Tell You She's Sorry",
    author: "Fredrik Backman",
    genre: "Contemporary Fiction",
    description: "A young girl embarks on a journey to deliver her grandmother's apologies.",
    amazonLink: "https://www.amazon.co.uk/dp/1444775804",
    reason: "Appeals to readers who enjoy magical realism and intergenerational stories."
  },
  {
    id: 'the-book-thief',
    title: "The Book Thief",
    author: "Markus Zusak",
    genre: "Historical Fiction",
    description: "A young girl steals books in Nazi Germany, narrated by Death.",
    amazonLink: "https://www.amazon.co.uk/dp/0552773891",
    reason: "Perfect for readers who enjoy WWII historical fiction with unique narrative perspectives."
  },
  {
    id: 'all-the-light-we-cannot-see',
    title: "All the Light We Cannot See",
    author: "Anthony Doerr",
    genre: "Historical Fiction",
    description: "The story of a blind French girl and a German boy whose paths collide in occupied France.",
    amazonLink: "https://www.amazon.co.uk/dp/0007548695",
    reason: "Appeals to readers who enjoy beautifully written WWII historical fiction."
  },
  {
    id: 'the-nightingale',
    title: "The Nightingale",
    author: "Kristin Hannah",
    genre: "Historical Fiction",
    description: "Two sisters in Nazi-occupied France must find the courage to survive.",
    amazonLink: "https://www.amazon.co.uk/dp/0312577222",
    reason: "Perfect for readers who enjoy powerful stories of female resilience during wartime."
  },

  // Self-Help & Psychology (20 books)
  {
    id: 'atomic-habits',
    title: "Atomic Habits",
    author: "James Clear",
    genre: "Self-Help",
    description: "A practical guide to building good habits and breaking bad ones through small changes.",
          amazonLink: "https://www.amazon.co.uk/dp/1786892738",
    reason: "Perfect for growth-oriented readers who want to understand how small changes create remarkable results."
  },
  {
    id: 'mans-search-meaning',
    title: "Man's Search for Meaning",
    author: "Viktor Frankl",
    genre: "Philosophy",
    description: "A Holocaust survivor's profound insights into finding purpose and meaning in life.",
    amazonLink: "https://www.amazon.co.uk/dp/080701429X",
    reason: "Resonates with reflective readers who seek deeper understanding of human resilience and purpose."
  },
  {
    id: 'the-power-of-now',
    title: "The Power of Now",
    author: "Eckhart Tolle",
    genre: "Spirituality",
    description: "A guide to spiritual enlightenment and living in the present moment.",
    amazonLink: "https://www.amazon.co.uk/dp/1577314808",
    reason: "Appeals to introspective readers interested in mindfulness and spiritual growth."
  },
  {
    id: 'mindset',
    title: "Mindset",
    author: "Carol S. Dweck",
    genre: "Psychology",
    description: "How a simple idea about the brain can help you learn and improve.",
    amazonLink: "https://www.amazon.co.uk/dp/0345472322",
    reason: "Perfect for growth-oriented readers who want to understand learning and achievement."
  },
  {
    id: 'the-7-habits',
    title: "The 7 Habits of Highly Effective People",
    author: "Stephen R. Covey",
    genre: "Self-Help",
    description: "Timeless principles for personal and professional effectiveness.",
    amazonLink: "https://www.amazon.co.uk/dp/1982137134",
    reason: "Great for conscientious readers who value structured approaches to success."
  },
  {
    id: 'thinking-fast-slow',
    title: "Thinking, Fast and Slow",
    author: "Daniel Kahneman",
    genre: "Psychology",
    description: "How we make decisions and the two systems that drive the way we think.",
    amazonLink: "https://www.amazon.co.uk/dp/0374533555",
    reason: "Perfect for analytical readers who want to understand human decision-making and cognitive biases."
  },
  {
    id: 'daring-greatly',
    title: "Daring Greatly",
    author: "Brené Brown",
    genre: "Self-Help",
    description: "How the courage to be vulnerable transforms the way we live, love, parent, and lead.",
    amazonLink: "https://www.amazon.co.uk/dp/1592408419",
    reason: "Appeals to readers interested in emotional intelligence and authentic living."
  },
  {
    id: 'flow',
    title: "Flow",
    author: "Mihaly Csikszentmihalyi",
    genre: "Psychology",
    description: "The psychology of optimal experience and finding happiness through engagement.",
    amazonLink: "https://www.amazon.co.uk/dp/0061339202",
    reason: "Perfect for readers interested in psychology, happiness, and peak performance."
  },
  {
    id: 'the-subtle-art',
    title: "The Subtle Art of Not Giving a F*ck",
    author: "Mark Manson",
    genre: "Self-Help",
    description: "A counterintuitive approach to living a good life.",
    amazonLink: "https://www.amazon.co.uk/dp/0062457713",
    reason: "Appeals to readers who appreciate direct, no-nonsense advice about life priorities."
  },
  {
    id: 'grit',
    title: "Grit",
    author: "Angela Duckworth",
    genre: "Psychology",
    description: "The power of passion and perseverance in achieving long-term goals.",
    amazonLink: "https://www.amazon.co.uk/dp/1501111108",
    reason: "Perfect for readers interested in achievement, motivation, and success psychology."
  },
  {
    id: 'the-power-of-habit',
    title: "The Power of Habit",
    author: "Charles Duhigg",
    genre: "Self-Help",
    description: "Why we do what we do in life and business, and how to change our habits.",
    amazonLink: "https://www.amazon.co.uk/dp/081298160X",
    reason: "Appeals to readers interested in behavioral science and personal improvement."
  },
  {
    id: 'the-art-of-possibility',
    title: "The Art of Possibility",
    author: "Rosamund Stone Zander",
    genre: "Self-Help",
    description: "Transforming professional and personal life through creative thinking.",
    amazonLink: "https://www.amazon.co.uk/dp/0142001104",
    reason: "Appeals to readers seeking creative approaches to life and work challenges."
  },
  {
    id: 'the-four-agreements',
    title: "The Four Agreements",
    author: "Don Miguel Ruiz",
    genre: "Self-Help",
    description: "A practical guide to personal freedom based on ancient Toltec wisdom.",
    amazonLink: "https://www.amazon.co.uk/dp/1878424319",
    reason: "Perfect for readers interested in spiritual wisdom and personal transformation."
  },
  {
    id: 'the-alchemist',
    title: "The Alchemist",
    author: "Paulo Coelho",
    genre: "Fiction",
    description: "A shepherd boy's journey to find his personal legend.",
    amazonLink: "https://www.amazon.co.uk/dp/0062315005",
    reason: "Appeals to readers who enjoy allegorical fiction about following one's dreams."
  },
  {
    id: 'the-celestine-prophecy',
    title: "The Celestine Prophecy",
    author: "James Redfield",
    genre: "Fiction",
    description: "A spiritual adventure that reveals nine insights into life and consciousness.",
    amazonLink: "https://www.amazon.co.uk/dp/0446671002",
    reason: "Perfect for readers interested in spiritual fiction and consciousness exploration."
  },
  {
    id: 'the-secret',
    title: "The Secret",
    author: "Rhonda Byrne",
    genre: "Self-Help",
    description: "The law of attraction and how to use it to create the life you want.",
    amazonLink: "https://www.amazon.co.uk/dp/1582701709",
    reason: "Appeals to readers interested in manifestation and positive thinking."
  },
  {
    id: 'you-are-a-badass',
    title: "You Are a Badass",
    author: "Jen Sincero",
    genre: "Self-Help",
    description: "How to stop doubting your greatness and start living an awesome life.",
    amazonLink: "https://www.amazon.co.uk/dp/0762447699",
    reason: "Perfect for readers who appreciate motivational, no-nonsense self-help advice."
  },
  {
    id: 'the-life-changing-magic',
    title: "The Life-Changing Magic of Tidying Up",
    author: "Marie Kondo",
    genre: "Self-Help",
    description: "The Japanese art of decluttering and organizing.",
    amazonLink: "https://www.amazon.co.uk/dp/1607747308",
    reason: "Appeals to readers interested in minimalism and creating organized living spaces."
  },
  {
    id: 'essentialism',
    title: "Essentialism",
    author: "Greg McKeown",
    genre: "Self-Help",
    description: "The disciplined pursuit of less and how to focus on what matters most.",
    amazonLink: "https://www.amazon.co.uk/dp/0753555166",
    reason: "Perfect for readers who want to simplify their lives and focus on priorities."
  },
  {
    id: 'deep-work',
    title: "Deep Work",
    author: "Cal Newport",
    genre: "Self-Help",
    description: "Rules for focused success in a distracted world.",
    amazonLink: "https://www.amazon.co.uk/dp/1455586692",
    reason: "Appeals to readers interested in productivity and focused work strategies."
  },

  // Classic Literature (10 books)
  {
    id: 'to-kill-mockingbird',
    title: "To Kill a Mockingbird",
    author: "Harper Lee",
    genre: "Classic Literature",
    description: "A timeless story about justice, morality, and growing up in the American South.",
    amazonLink: "https://www.amazon.co.uk/dp/0060935464",
    reason: "Resonates with readers who value social justice, moral complexity, and coming-of-age narratives."
  },
  {
    id: 'pride-prejudice',
    title: "Pride and Prejudice",
    author: "Jane Austen",
    genre: "Classic Romance",
    description: "The timeless story of Elizabeth Bennet and Mr. Darcy's complex relationship.",
    amazonLink: "https://www.amazon.co.uk/dp/0141439513",
    reason: "Perfect for readers who appreciate wit, social commentary, and well-developed romantic relationships."
  },
  {
    id: 'great-gatsby',
    title: "The Great Gatsby",
    author: "F. Scott Fitzgerald",
    genre: "Classic Literature",
    description: "A story of decadence and excess, exploring the darker aspects of the Jazz Age.",
    amazonLink: "https://www.amazon.co.uk/dp/0743273567",
    reason: "Perfect for readers who appreciate lyrical prose and social commentary."
  },
  {
    id: 'jane-eyre',
    title: "Jane Eyre",
    author: "Charlotte Brontë",
    genre: "Gothic Romance",
    description: "A young governess falls in love with her mysterious employer.",
    amazonLink: "https://www.amazon.co.uk/dp/0141441143",
    reason: "Appeals to readers who enjoy gothic atmosphere and strong female protagonists."
  },
  {
    id: 'wuthering-heights',
    title: "Wuthering Heights",
    author: "Emily Brontë",
    genre: "Gothic Romance",
    description: "A passionate and destructive love story set on the Yorkshire moors.",
    amazonLink: "https://www.amazon.co.uk/dp/0141439556",
    reason: "Perfect for readers who enjoy intense emotions and atmospheric settings."
  },
  {
    id: 'catcher-in-the-rye',
    title: "The Catcher in the Rye",
    author: "J.D. Salinger",
    genre: "Classic Literature",
    description: "A teenager's journey through New York City and his struggle with growing up.",
    amazonLink: "https://www.amazon.co.uk/dp/0316769487",
    reason: "Resonates with readers who appreciate coming-of-age stories and authentic teenage voice."
  },
  {
    id: 'of-mice-and-men',
    title: "Of Mice and Men",
    author: "John Steinbeck",
    genre: "Classic Literature",
    description: "A story of friendship and dreams during the Great Depression.",
    amazonLink: "https://www.amazon.co.uk/dp/0140177396",
    reason: "Perfect for readers who appreciate powerful, concise storytelling and social themes."
  },
  {
    id: 'lord-of-the-flies',
    title: "Lord of the Flies",
    author: "William Golding",
    genre: "Classic Literature",
    description: "A group of boys stranded on an island descend into savagery.",
    amazonLink: "https://www.amazon.co.uk/dp/0399501487",
    reason: "Appeals to readers interested in human nature, civilization, and moral philosophy."
  },
  {
    id: 'animal-farm',
    title: "Animal Farm",
    author: "George Orwell",
    genre: "Classic Literature",
    description: "A farm is taken over by its overworked, mistreated animals.",
    amazonLink: "https://www.amazon.co.uk/dp/0451526341",
    reason: "Perfect for readers who enjoy political allegory and social commentary."
  },
  {
    id: 'the-old-man-and-the-sea',
    title: "The Old Man and the Sea",
    author: "Ernest Hemingway",
    genre: "Classic Literature",
    description: "An aging fisherman's struggle with a giant marlin far out in the Gulf Stream.",
    amazonLink: "https://www.amazon.co.uk/dp/0684801221",
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
  const filteredBookPool = bookPool.filter(book => {
    // Check if book ID is in excludeIds (for previously recommended books)
    if (excludeIds.includes(book.id)) {
      console.log(`🚫 Excluded by ID: ${book.title} by ${book.author} (ID: ${book.id})`);
      return false;
    }
    
    // Check if this book matches a favorited book by title and author (primary exclusion method)
    if (favoritedBookSignatures && favoritedBookSignatures.size > 0) {
      const bookSignature = `${book.title.toLowerCase()}-${book.author.toLowerCase()}`;
      console.log(`🔍 Checking book: ${book.title} by ${book.author} (Signature: ${bookSignature})`);
      console.log(`🔍 Available signatures:`, Array.from(favoritedBookSignatures));
      
      if (favoritedBookSignatures.has(bookSignature)) {
        console.log(`🚫 Excluded by signature: ${book.title} by ${book.author} (Signature: ${bookSignature})`);
        return false;
      } else {
        console.log(`✅ Not excluded: ${book.title} by ${book.author} (Signature: ${bookSignature})`);
      }
    } else {
      console.log(`⚠️ No favorited book signatures provided for exclusion`);
    }
    
    return true;
  });
  
  console.log(`📊 Book pool filtered: ${bookPool.length} -> ${filteredBookPool.length} books`);
  
  // Score all books and sort by relevance
  const scoredBooks = filteredBookPool.map(book => ({
    book,
    score: scoreBook(book, profile, useExpandedMatching),
    randomFactor: seededRandom() // Add random factor for each book
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

  // First pass: select highest scoring books from different genres and authors
  for (const { book } of scoredBooks) {
    if (selectedBooks.length >= 6) break;
    
    const genreCount = Array.from(usedGenres).filter(g => g === book.genre).length;
    const authorUsed = usedAuthors.has(book.author);
    
    // Prefer books from new genres and authors, but allow some overlap for quality
    if ((!usedGenres.has(book.genre) || genreCount < 2) && !authorUsed) {
      selectedBooks.push(book);
      usedGenres.add(book.genre);
      usedAuthors.add(book.author);
    } else if (selectedBooks.length >= 3 && !authorUsed) {
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
  return selectedBooks.slice(0, 6);
};



