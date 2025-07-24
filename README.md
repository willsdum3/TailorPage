# TailorPage 📚

A personality-driven book recommendation application that matches readers with their perfect next book based on comprehensive personality profiling.

## Overview

TailorPage combines psychology and literature to deliver personalized book recommendations. Users complete a 50-question personality assessment covering 10 psychological dimensions, and our sophisticated algorithm matches them with books from a curated database of 1000+ titles across all genres.

## Features

### 🧠 Personality Assessment
- **50-question quiz** covering 10 personality dimensions:
  - Big Five traits: Openness, Conscientiousness, Extraversion, Agreeableness, Emotional Stability
  - Additional dimensions: Rational Thinking, Core Values, Lifestyle, Social Style, Self-Expression
- **Progress persistence** - resume your quiz anytime
- **Scientifically-informed** scoring system

### 📖 Smart Recommendations
- **Personalized matching** using advanced scoring algorithms
- **Genre diversity** ensuring varied recommendations
- **1000+ curated books** across all genres and reading preferences
- **Detailed explanations** for why each book matches your personality
- **Amazon integration** for easy purchasing

### 👤 User Experience
- **Clean, modern interface** with responsive design
- **User authentication** (ready for Supabase integration)
- **Favorites system** to save your preferred recommendations
- **Multiple discovery pages**: Trending Books, Trending Authors, Celebrity Tester
- **Progressive enhancement** - works without JavaScript for core functionality

### 🔄 Dynamic Content
- **Fresh recommendations** on each session to prevent repetition
- **Exclusion system** prevents showing previously recommended books
- **Randomization factor** maintains variety while preserving personality relevance

## Technology Stack

### Frontend
- **React 18** with TypeScript for type-safe development
- **Vite** for fast development and optimized builds
- **Tailwind CSS** for responsive, utility-first styling
- **Lucide React** for consistent iconography

### Backend Ready
- **Supabase** client configured for authentication and database
- **Mock authentication** currently implemented for development

### Development & Deployment
- **ESLint** with React and TypeScript configurations
- **Docker** containerization with multi-stage builds
- **Nginx** for production serving

## Quick Start

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Docker (optional, for containerized deployment)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TailorPage
   ```

2. **Install dependencies**
   ```bash
   cd project/
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

4. **Open your browser**
   ```
   http://localhost:5173
   ```

### Docker Deployment (Recommended)

1. **Build the Docker image**
   ```bash
   docker build -t tailorpage .
   ```

2. **Run the container**
   ```bash
   docker run -p 3000:80 tailorpage
   ```

3. **Access the application**
   ```
   http://localhost:3000
   ```

> **Note**: After updating environment variables (like Clerk keys), rebuild the Docker image to pick up changes.

## Development Commands

```bash
# Docker (Primary workflow)
docker build -t tailorpage .     # Build image
docker run -p 3000:80 tailorpage # Run container

# Local Development (Alternative)
cd project/
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
```

## Project Structure

```
TailorPage/
├── project/                 # Main React application
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── data/           # Static data (celebrities, trending books)
│   │   ├── utils/          # Utility functions and algorithms
│   │   ├── App.tsx         # Main application component
│   │   ├── types.ts        # TypeScript type definitions
│   │   └── supabaseClient.ts # Database client configuration
│   ├── public/             # Static assets
│   ├── package.json        # Dependencies and scripts
│   └── vite.config.ts      # Vite configuration
├── Dockerfile              # Container configuration
├── CLAUDE.md              # AI assistant documentation
└── README.md              # This file
```

## How It Works

### Personality Assessment
The quiz evaluates users across 10 psychological dimensions using a 5-point Likert scale. Questions are carefully designed to assess:

- **Cognitive preferences** (openness, rational thinking)
- **Behavioral tendencies** (conscientiousness, extraversion)
- **Interpersonal style** (agreeableness, social style)
- **Emotional patterns** (emotional stability, self-expression)
- **Value systems** (core values, lifestyle preferences)

### Recommendation Algorithm
Our sophisticated matching system:

1. **Scores each book** based on genre alignment with personality traits
2. **Applies trait-specific weightings** (e.g., high openness → fantasy/sci-fi boost)
3. **Ensures diversity** by preventing author and genre repetition
4. **Adds controlled randomization** for variety while maintaining relevance
5. **Excludes previously recommended books** to keep suggestions fresh

### Genre Matching Examples
- **High Openness + Low Conscientiousness** → Fantasy, Science Fiction
- **High Agreeableness + Self-Expression** → Memoirs, Contemporary Fiction
- **High Rational Thinking + Conscientiousness** → Science, History, Psychology
- **High Emotional Stability** → Thrillers, Dark Fantasy, Complex Literature

## Contributing

We welcome contributions! Areas for enhancement:

- **Additional books** in the recommendation database
- **New personality dimensions** for more precise matching
- **UI/UX improvements** for better user experience
- **Mobile optimization** for tablet and phone usage
- **Social features** for sharing recommendations
- **Reading progress tracking** integration

## Configuration

### Environment Variables
Currently using mock authentication. For Supabase integration:

```env
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Customization
- **Book database**: Edit `src/utils/bookRecommendations.ts`
- **Personality questions**: Modify questions array in `src/App.tsx`
- **Styling**: Update Tailwind configuration in `tailwind.config.js`
- **Scoring algorithm**: Adjust weightings in the `scoreBook` function

## License

[Add your license here]

## Support

For questions, bug reports, or feature requests, please [open an issue](repository-issues-url) or contact the development team.

---

**Built with ❤️ for book lovers who want their next great read tailored to their unique personality.**