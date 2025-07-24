# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TailorPage is a React-based personality quiz application that recommends books based on user personality profiles. The application features:

- **Personality Quiz**: 50-question assessment covering openness, conscientiousness, extraversion, agreeableness, emotional stability, rational thinking, core values, lifestyle, social style, and self-expression
- **Book Recommendations**: AI-powered book matching system with 1000+ books across multiple genres
- **User Authentication**: Clerk authentication with SSO support (Google, Apple, Facebook, Microsoft)
- **Favorites System**: Users can save recommended books to their personal favorites
- **Multiple Pages**: Welcome, quiz, results, trending books/authors, celebrity tester, favorites, and learn more sections

## Architecture

### Main Application Structure (`/project/`)
- **Frontend**: React 18 with TypeScript, using Vite as build tool
- **Styling**: Tailwind CSS for responsive design with custom gradient backgrounds
- **State Management**: React hooks with local state (no external state library)
- **Navigation**: Custom burger menu with page-based routing system
- **Authentication**: Clerk for user management with OAuth providers

### Key Files and Components
- `src/App.tsx` - Main application component with state management and page routing
- `src/types.ts` - TypeScript interfaces for personality profiles, books, users, and quiz data
- `src/utils/bookRecommendations.ts` - Complex algorithm for personality-based book matching
- `src/supabaseClient.ts` - Supabase client configuration (credentials included for development)
- `src/components/` - All React components organized by feature

### Book Recommendation System
The core recommendation engine (`bookRecommendations.ts`) uses a sophisticated scoring algorithm that:
- Analyzes 10 personality traits from quiz responses
- Matches books from a curated database of 1000+ titles across genres
- Applies genre-based scoring with personality trait weightings
- Ensures diversity by avoiding author/genre repetition
- Returns exactly 6 personalized recommendations per session

## Development Commands

### Docker Development (Primary)
```bash
# Build Docker image (from root directory)
docker build -t tailorpage .

# Run Docker container
docker run -p 3000:80 tailorpage

# Access application at http://localhost:3000
```

### Local Development (Alternative)
```bash
cd project/
npm run dev          # Start development server (usually localhost:5173)
npm run build        # Build for production
npm run preview      # Preview production build locally
npm run lint         # Run ESLint for code quality
```

### Package Management
```bash
# Main dependency management happens in /project/ directory
cd project/
npm install          # Install dependencies
npm ci               # Clean install for production
```

## Code Architecture Patterns

### State Management
- Uses React hooks (useState, useEffect) for local state
- Main state in App.tsx includes: current page, quiz answers, personality profile, favorites, user auth
- State is passed down through props rather than context (suitable for current app size)

### Component Organization
- Page components handle full-screen views (WelcomePage, QuizPage, ResultsPage, etc.)
- Shared components like AuthButton and BurgerMenu handle cross-page functionality
- Each component follows single responsibility principle

### Data Flow
1. **Quiz Flow**: Questions → Answers → Personality Profile → Book Recommendations
2. **Auth Flow**: Mock login/signup → User state → Protected features
3. **Favorites Flow**: Book recommendations → User selections → Persistent favorites list

### TypeScript Usage
- Comprehensive type definitions in `types.ts` 
- Strict typing for personality profiles, quiz responses, and book data
- Custom types for navigation, authentication, and user interactions

## Key Configuration Files

- `package.json` - Dependencies and scripts (React 18, TypeScript, Tailwind CSS)
- `vite.config.ts` - Vite configuration with React plugin
- `tailwind.config.js` - Tailwind CSS configuration for styling
- `tsconfig.json` - TypeScript configuration files (app and node variants)
- `eslint.config.js` - ESLint configuration with React hooks and TypeScript

## Development Notes

### Authentication
- Uses Clerk for user authentication and management
- Supports OAuth providers: Google, Apple, Facebook, Microsoft
- Email/password authentication also available
- User state automatically managed by Clerk hooks

### Book Data
- Large book database embedded in `bookRecommendations.ts`
- Each book includes: title, author, genre, description, Amazon link, and personalized reason
- Books span genres: Literary Fiction, Fantasy, Sci-Fi, Self-Help, Biography, Thriller, Classic Literature, History/Science, Contemporary/Romance

### Personality Algorithm
- Complex scoring system based on Big Five personality traits plus additional dimensions
- Genre preferences mapped to personality characteristics
- Randomization factor ensures variety while maintaining relevance
- Exclusion system prevents duplicate recommendations across sessions

### State Persistence
- Quiz progress is maintained during session
- Favorites persist during user session
- No localStorage or external persistence currently implemented

## Testing
No test framework is currently configured. The application relies on development testing and ESLint for code quality.

## Deployment

### Docker Deployment
The application is containerized with a multi-stage Docker build:
- **Stage 1**: Node.js Alpine image builds the React application
- **Stage 2**: Nginx Alpine serves the static files on port 80
- Dockerfile is located in the root directory and handles the `/project/` subfolder structure

### Build Output
- Production builds are generated in `/project/dist/`
- Can be deployed to any static hosting service or run in Docker containers
- Docker container exposes the application on port 80 (map to any host port)