import React, { useState } from 'react';
import { ArrowLeft, User, BookOpen, Users, ExternalLink, Search, Filter, TrendingUp, Sparkles, Twitter, Instagram, Globe, Star } from 'lucide-react';
import { trendingAuthors, TrendingAuthor } from '../data/trendingAuthors';
import Logo from './Logo';

interface TrendingAuthorsPageProps {
  onBack: () => void;
}

const TrendingAuthorsPage: React.FC<TrendingAuthorsPageProps> = ({ onBack }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedGenre, setSelectedGenre] = useState('All');
  const [sortBy, setSortBy] = useState('rank');

  // Get unique genres
  const genres = ['All', ...Array.from(new Set(trendingAuthors.map(author => author.genre)))].sort();

  // Filter and sort authors
  const filteredAuthors = trendingAuthors
    .filter(author => {
      const matchesSearch = author.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           author.bio.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           author.popularBooks.some(book => book.toLowerCase().includes(searchTerm.toLowerCase()));
      const matchesGenre = selectedGenre === 'All' || author.genre === selectedGenre;
      return matchesSearch && matchesGenre;
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'rank':
          return a.rank - b.rank;
        case 'followers':
          return b.followers - a.followers;
        case 'books':
          return b.totalBooks - a.totalBooks;
        case 'name':
          return a.name.localeCompare(b.name);
        case 'genre':
          return a.genre.localeCompare(b.genre);
        default:
          return a.rank - b.rank;
      }
    });

  const formatNumber = (num: number) => {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
      return (num / 1000).toFixed(0) + 'K';
    }
    return num.toString();
  };

  const getSocialIcon = (platform: string) => {
    switch (platform) {
      case 'twitter':
        return <Twitter className="w-4 h-4" />;
      case 'instagram':
        return <Instagram className="w-4 h-4" />;
      case 'tiktok':
        return <span className="w-4 h-4 text-xs font-bold">TT</span>;
      case 'website':
        return <Globe className="w-4 h-4" />;
      default:
        return <ExternalLink className="w-4 h-4" />;
    }
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
          
          <div className="mb-8">
            <Logo size="lg" showText={true} />
          </div>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <TrendingUp className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Most Popular Authors</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Trending
            <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Authors
            </span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover the top 10 most trending authors of the past 3 months. From breakthrough debuts to established masters, these writers are capturing readers' hearts worldwide.
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
                placeholder="Search authors or books..."
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
                <option value="rank" className="bg-slate-800 text-white">Trending Rank</option>
                <option value="followers" className="bg-slate-800 text-white">Most Followers</option>
                <option value="books" className="bg-slate-800 text-white">Most Books</option>
                <option value="name" className="bg-slate-800 text-white">Name A-Z</option>
                <option value="genre" className="bg-slate-800 text-white">Genre</option>
              </select>
            </div>

            {/* Results Count */}
            <div className="flex items-center justify-center bg-white/5 border border-white/20 rounded-xl px-4 py-3">
              <span className="text-white/80 font-medium">
                {filteredAuthors.length} author{filteredAuthors.length !== 1 ? 's' : ''}
              </span>
            </div>
          </div>
        </div>

        {/* Authors Grid */}
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-5 mb-16">
          {filteredAuthors.map((author) => (
            <div key={author.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
              {/* Author Header */}
              <div className="flex items-start space-x-4 mb-6">
                <div className="relative">
                  <img
                    src={author.imageUrl}
                    alt={author.name}
                    className="w-16 h-16 rounded-xl object-cover border-2 border-white/20 group-hover:border-amber-400/50 transition-colors duration-300"
                  />
                  <div className="absolute -top-2 -right-2 bg-gradient-to-r from-amber-500 to-orange-600 text-white px-2 py-1 rounded-full text-xs font-bold">
                    #{author.rank}
                  </div>
                </div>
                
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-white mb-1 group-hover:text-amber-400 transition-colors duration-300">
                    {author.name}
                  </h3>
                  <p className="text-amber-400 font-medium text-sm mb-2">{author.genre}</p>
                  <div className="flex items-center space-x-4 text-white/60 text-sm">
                    <div className="flex items-center space-x-1">
                      <BookOpen className="w-4 h-4" />
                      <span>{author.totalBooks} books</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <Users className="w-4 h-4" />
                      <span>{formatNumber(author.followers)}</span>
                    </div>
                  </div>
                </div>
              </div>
                <h2 className="text-3xl font-bold text-white">Discover Books by Your Personality</h2>
              {/* Bio */}
              <p className="text-white/70 text-sm mb-4 leading-relaxed">
                While these authors are trending now, our AI can recommend books from any author that perfectly match your unique reading personality and preferences.
              </p>

              {/* Popular Books */}
              <div className="mb-4">
                <h4 className="text-white font-semibold text-sm mb-2">Popular Books:</h4>
                <div className="space-y-1">
                  {author.popularBooks.slice(0, 3).map((book, index) => (
                    <div key={index} className="flex items-center space-x-2">
                      <Star className="w-3 h-3 text-amber-400 fill-current" />
                      <span className="text-white/80 text-sm">{book}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Recent Activity */}
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-3 mb-4">
                <p className="text-xs text-white/80">
                  <span className="font-medium text-amber-400">Recent:</span> {author.recentActivity}
                </p>
              </div>

              {/* Social Links */}
              {author.socialMedia && (
                <div className="flex items-center space-x-2 mb-4">
                  {Object.entries(author.socialMedia).map(([platform, handle]) => (
                    <a
                      key={platform}
                      href={
                        platform === 'website' ? handle :
                        platform === 'tiktok' ? `https://tiktok.com/${handle.replace('@', '')}` :
                        `https://${platform}.com/${handle.replace('@', '')}`
                      }
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-white/10 hover:bg-white/20 text-white/70 hover:text-white p-2 rounded-lg transition-all duration-300 transform hover:scale-110"
                      title={handle}
                    >
                      {getSocialIcon(platform)}
                    </a>
                  ))}
                </div>
              )}

              {/* Amazon Link */}
            </div>
          ))}
        </div>

        {/* No Results */}
        {filteredAuthors.length === 0 && (
          <div className="text-center py-16">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl mb-6">
              <Search className="w-10 h-10 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white mb-4">No Authors Found</h3>
            <p className="text-white/70 mb-8 max-w-md mx-auto">
              Try adjusting your search terms or filters to find more authors.
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
          <div className="mb-8">
            <div className="inline-flex items-center space-x-2 mb-4">
              <Sparkles className="w-6 h-6 text-amber-400" />
              <h2 className="text-3xl font-bold text-white">Discover Books by Your Personality</h2>
            </div>
            <p className="text-white/70 mb-8 max-w-2xl mx-auto">
              While these authors are trending now, our AI can recommend books from any author that perfectly match your unique reading personality and preferences.
            </p>
          </div>
          
          <button
            onClick={onBack}
            className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
          >
            <span>Take Personality Quiz</span>
            <ArrowLeft className="w-5 h-5 rotate-180" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default TrendingAuthorsPage;