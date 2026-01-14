// Tests for SnackyNerds Frontend
import { render, screen } from '@testing-library/react';
import App from './App';
import { describe, it, expect, vi } from 'vitest';

describe('App', () => {
  it('renders SnackyNerds title', () => {
    // Mock fetch to return empty snacks array
    global.fetch = vi.fn(() =>
      Promise.resolve({ json: () => Promise.resolve([]) })
    );

    render(<App />);
    const title = screen.getByText(/SnackyNerds/i);
    expect(title).toBeInTheDocument();
  });
});
