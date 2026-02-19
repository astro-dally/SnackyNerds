import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import App from './App';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BrowserRouter } from 'react-router-dom';

// App uses Routes, so it needs a Router context.
const MockApp = () => (
  <BrowserRouter>
    <App />
  </BrowserRouter>
);

describe('App Integration', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Default mock response for fetch
    global.fetch = vi.fn(() =>
      Promise.resolve({
        json: () => Promise.resolve([
          { id: 1, name: 'Avocado Chips', price: 15, emoji: '🥑', description: 'Healthy' }
        ]),
      })
    );
  });

  it('renders homepage and fetches snacks', async () => {
    render(<MockApp />);
    const headings = screen.getAllByText(/SNACKYNERDS/i);
    expect(headings.length).toBeGreaterThan(0);
    
    await waitFor(() => {
        expect(screen.getByText('Avocado Chips')).toBeInTheDocument();
        expect(screen.getByText('15 🪙')).toBeInTheDocument();
    });
  });

  it('adds snack to cart and updates header', async () => {
    render(<MockApp />);
    
    await waitFor(() => {
        expect(screen.getByText('Avocado Chips')).toBeInTheDocument();
    });

    const addBtn = screen.getByText('ADD TO PACK +');
    fireEvent.click(addBtn);

    // Check if cart count updated in header
    // The button text is "CART (1)"
    expect(screen.getByText(/CART \(1\)/i)).toBeInTheDocument();
  });
});
