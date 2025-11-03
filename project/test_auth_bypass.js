// Test Authentication Bypass
// This script can be run in the browser console to test the app with test users

// Override the getCurrentUserId function to return a test user ID
function setupTestAuth() {
    // Get the Supabase client (assuming it's available globally)
    if (typeof supabase === 'undefined') {
        console.error('Supabase client not found. Make sure it\'s available globally.');
        return;
    }
    
    // Override the getCurrentUserId function
    window.originalGetCurrentUserId = window.originalGetCurrentUserId || TailorMatesService.getCurrentUserId;
    
    TailorMatesService.getCurrentUserId = async function() {
        // Return a test user ID
        return '00000000-0000-0000-0000-000000000001';
    };
    
    console.log('Test authentication bypass set up. Using test user: 00000000-0000-0000-0000-000000000001');
}

// Test function to load book clubs
async function testLoadBookClubs() {
    try {
        console.log('Testing getBookClubs...');
        const clubs = await TailorMatesService.getBookClubs();
        console.log('Book clubs loaded:', clubs);
        return clubs;
    } catch (error) {
        console.error('Error loading book clubs:', error);
        return null;
    }
}

// Test function to load discussions
async function testLoadDiscussions() {
    try {
        console.log('Testing getDiscussions...');
        const discussions = await TailorMatesService.getDiscussions();
        console.log('Discussions loaded:', discussions);
        return discussions;
    } catch (error) {
        console.error('Error loading discussions:', error);
        return null;
    }
}

// Main test function
async function runTests() {
    console.log('Setting up test authentication...');
    setupTestAuth();
    
    console.log('Testing book clubs...');
    const clubs = await testLoadBookClubs();
    
    console.log('Testing discussions...');
    const discussions = await testLoadDiscussions();
    
    console.log('Test complete!');
    return { clubs, discussions };
}

// Export functions for use
window.setupTestAuth = setupTestAuth;
window.testLoadBookClubs = testLoadBookClubs;
window.testLoadDiscussions = testLoadDiscussions;
window.runTests = runTests;

console.log('Test authentication bypass loaded. Run runTests() to test the app.');
