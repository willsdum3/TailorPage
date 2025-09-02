-- Fix broken Amazon links in the database schema
-- This script updates the sample data with working Amazon search URLs

-- Update the sample books with working Amazon links
UPDATE books 
SET amazon_link = 'https://www.amazon.co.uk/s?k=The+Great+Gatsby+F.+Scott+Fitzgerald'
WHERE title = 'The Great Gatsby' AND author = 'F. Scott Fitzgerald';

UPDATE books 
SET amazon_link = 'https://www.amazon.co.uk/s?k=1984+George+Orwell'
WHERE title = '1984' AND author = 'George Orwell';

UPDATE books 
SET amazon_link = 'https://www.amazon.co.uk/s?k=Pride+and+Prejudice+Jane+Austen'
WHERE title = 'Pride and Prejudice' AND author = 'Jane Austen';

-- If you want to insert new books with working links instead of updating:
-- DELETE FROM books WHERE title IN ('The Great Gatsby', '1984', 'Pride and Prejudice');

-- INSERT INTO books (title, author, genre, description, amazon_link, cover_image_url) 
-- VALUES 
-- ('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', 'A story of the fabulously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan.', 'https://www.amazon.co.uk/s?k=The+Great+Gatsby+F.+Scott+Fitzgerald', 'https://example.com/gatsby.jpg'),
-- ('1984', 'George Orwell', 'Dystopian', 'A dystopian social science fiction novel and cautionary tale.', 'https://www.amazon.co.uk/s?k=1984+George+Orwell', 'https://example.com/1984.jpg'),
-- ('Pride and Prejudice', 'Jane Austen', 'Romance', 'A romantic novel of manners that follows the emotional development of Elizabeth Bennet.', 'https://www.amazon.co.uk/s?k=Pride+and+Prejudice+Jane+Austen', 'https://example.com/pride.jpg');

-- Verify the updates
SELECT title, author, amazon_link FROM books WHERE title IN ('The Great Gatsby', '1984', 'Pride and Prejudice');
