import React, { useState } from 'react';
import { ArrowLeft, Book, ShoppingCart, ExternalLink, Star, Search, Filter, TrendingUp, Sparkles } from 'lucide-react';
import { trendingBooks, TrendingBook } from '../data/trendingBooks';
import BookCover from './BookCover';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';

interface TrendingBooksPageProps {
  onBack: () => void;
  hasCompletedQuiz: boolean;
  onStartQuiz?: () => void;
}

const TrendingBooksPage: React.FC<TrendingBooksPageProps> = ({ onBack, hasCompletedQuiz, onStartQuiz }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedGenre, setSelectedGenre] = useState('All');
  const [sortBy, setSortBy] = useState('rank');

  // Scroll to top when component mounts
  useScrollToTopInstant([]);

  // Get unique genres
  const genres = ['All', ...Array.from(new Set(trendingBooks.map(book => book.genre)))].sort();

  // Filter and sort books
  const filteredBooks = trendingBooks
    .filter(book => {
      const matchesSearch = book.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           book.author.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesGenre = selectedGenre === 'All' || book.genre === selectedGenre;
      return matchesSearch && matchesGenre;
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'rank':
          return a.rank - b.rank;
        case 'rating':
          return b.rating - a.rating;
        case 'reviews':
          return b.reviewCount - a.reviewCount;
        case 'price':
          return parseFloat(a.price.replace('£', '')) - parseFloat(b.price.replace('£', ''));
        case 'title':
          return a.title.localeCompare(b.title);
        case 'author':
          return a.author.localeCompare(b.author);
        default:
          return a.rank - b.rank;
      }
    });

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`w-4 h-4 ${
          i < Math.floor(rating) 
            ? 'text-amber-400 fill-current' 
            : i < rating 
              ? 'text-amber-400 fill-current opacity-50' 
              : 'text-gray-400'
        }`}
      />
    ));
  };

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-12">
          <button
            onClick={onBack}
            className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Home</span>
          </button>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <TrendingUp className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Amazon Bestsellers</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Trending <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Books</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover the top 10 bestselling books on Amazon UK. From gripping thrillers to heartwarming romances, find your next great read from what everyone is talking about.
          </p>
        </div>

        {/* Filters and Search */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
          <div className="grid md:grid-cols-4 gap-4">
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
              <input
                type="text"
                placeholder="Search books or authors..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
              />
            </div>

            {/* Genre Filter */}
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
              <select
                value={selectedGenre}
                onChange={(e) => setSelectedGenre(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200 appearance-none cursor-pointer"
              >
                {genres.map(genre => (
                  <option key={genre} value={genre} className="bg-slate-800 text-white">
                    {genre}
                  </option>
                ))}
              </select>
            </div>

            {/* Sort By */}
            <div>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="w-full px-4 py-3 bg-white/5 border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200 appearance-none cursor-pointer"
              >
                <option value="rank" className="bg-slate-800 text-white">Bestseller Rank</option>
                <option value="rating" className="bg-slate-800 text-white">Highest Rated</option>
                <option value="reviews" className="bg-slate-800 text-white">Most Reviews</option>
                <option value="price" className="bg-slate-800 text-white">Price: Low to High</option>
                <option value="title" className="bg-slate-800 text-white">Title A-Z</option>
                <option value="author" className="bg-slate-800 text-white">Author A-Z</option>
              </select>
            </div>

            {/* Results Count */}
            <div className="flex items-center justify-center bg-white/5 border border-white/20 rounded-xl px-4 py-3">
              <span className="text-white/80 font-medium">
                {filteredBooks.length} book{filteredBooks.length !== 1 ? 's' : ''}
              </span>
            </div>
          </div>
        </div>

        {/* Books Grid */}
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 mb-16">
          {filteredBooks.map((book) => (
            <div key={book.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
              {/* Rank Badge */}
              <div className="flex items-center justify-between mb-4">
                <div className="bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-bold">
                  #{book.rank}
                </div>
                <div className="text-right">
                  <div className="text-white font-bold text-lg">{book.price}</div>
                </div>
              </div>

              {/* Book Info */}
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="inline-block bg-white/10 text-white/80 px-2 py-1 rounded-lg text-xs font-medium">
                    {book.genre}
                  </span>
                  <BookCover 
                    bookId={book.id}
                    title={book.title}
                    author={book.author}
                    size="sm"
                    className="flex-shrink-0"
                    genre={book.genre}
                    description={book.description}
                    amazonLink={book.amazonLink}
                    coverImage={book.coverImage}
                  />
                </div>
                
                <h3 className="text-lg font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300 line-clamp-2">
                  {book.title}
                </h3>
                <p className="text-white/70 font-medium mb-3">by {book.author}</p>
              </div>
              
              <p className="text-white/70 text-sm mb-4 leading-relaxed line-clamp-3">
                While these are the most popular books right now, our AI can find books that are perfectly tailored to your unique personality and reading preferences.
              </p>

              {/* Rating */}
              <div className="flex items-center space-x-2 mb-4">
                <div className="flex items-center space-x-1">
                  {renderStars(book.rating)}
                </div>
                <span className="text-white/80 text-sm font-medium">{book.rating}</span>
                <span className="text-white/60 text-sm">({book.reviewCount.toLocaleString()} reviews)</span>
              </div>
              
              {/* Buy Button */}
              <a
                href={book.amazonLink}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center space-x-2 w-full group"
              >
                <ShoppingCart className="w-4 h-4" />
                <span>Buy on Amazon</span>
                <ExternalLink className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </a>
            </div>
          ))}
        </div>

        {/* No Results */}
        {filteredBooks.length === 0 && (
          <div className="text-center py-16">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl mb-6">
              <Search className="w-10 h-10 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white mb-4">No Books Found</h3>
            <p className="text-white/70 mb-8 max-w-md mx-auto">
              Try adjusting your search terms or filters to find more books.
            </p>
            <button
              onClick={() => {
                setSearchTerm('');
                setSelectedGenre('All');
                setSortBy('rank');
              }}
              className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105"
            >
              Clear Filters
            </button>
          </div>
        )}

        {/* Bottom CTA */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
          {hasCompletedQuiz ? (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Enjoying Tailor Page?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  Share the app with your friends on social media!
                </p>
                <div className="flex flex-wrap justify-center gap-4">
                  <a href="https://www.facebook.com/sharer/sharer.php?u=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-400/30">
                    <img src="/facebooklogo5.jpg" alt="Facebook" className="w-8 h-8 rounded-md object-cover" />
                    <span>Facebook</span>
                  </a>
                  <a href="https://twitter.com/intent/tweet?url=https://your-app-url.com&text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-black/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-gray-400/30">
                    <img src="/xlogo2.jpg" alt="X" className="w-8 h-8 rounded-md object-cover" />
                    <span>X</span>
                  </a>
                  <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-600/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-500/30">
                    <img src="/linkedinlogo3.jpg" alt="LinkedIn" className="w-8 h-8 rounded-md object-cover" />
                    <span>LinkedIn</span>
                  </a>
                  <a href="https://reddit.com/submit?url=https://your-app-url.com&title=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-orange-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-orange-400/30">
                    <img src="/Redditlogo5.png" alt="Reddit" className="w-8 h-8 rounded-md object-cover" />
                    <span>Reddit</span>
                  </a>
                  <a href="https://api.whatsapp.com/send?text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!%20https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-green-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-green-400/30">
                    <img src="/whatsapplogo3.jpg" alt="WhatsApp" className="w-8 h-8 rounded-md object-cover" />
                    <span>WhatsApp</span>
                  </a>
                  <a href="https://www.instagram.com/" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-pink-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-pink-400/30">
                    <img src="/instagramlogo3.jpg" alt="Instagram" className="w-8 h-8 rounded-md object-cover" />
                    <span>Instagram</span>
                  </a>
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Want Personalised Recommendations?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  While these are the most popular books right now, our AI can find books that are perfectly tailored to your unique personality and reading preferences.
                </p>
              </div>
              <button
                onClick={onStartQuiz || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <span>Take Personality Quiz</span>
                <ArrowLeft className="w-5 h-5 rotate-180" />
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default TrendingBooksPage;