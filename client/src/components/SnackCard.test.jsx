import { render, screen, fireEvent, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import SnackCard from './SnackCard';

describe('SnackCard', () => {
    const mockSnack = {
        id: 1,
        name: 'Chips',
        emoji: '🥔',
        description: 'Crunchy',
        price: 10
    };
    const mockAddToCart = vi.fn();
    const mockOnDiscover = vi.fn();

    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders snack details', () => {
        render(
            <SnackCard 
                snack={mockSnack} 
                addToCart={mockAddToCart} 
                isHidden={false} 
                hasDiscovered={false} 
                onDiscover={mockOnDiscover} 
            />
        );

        expect(screen.getByText('Chips')).toBeInTheDocument();
        expect(screen.getByText('🥔')).toBeInTheDocument();
        expect(screen.getByText('Crunchy')).toBeInTheDocument();
        expect(screen.getByText('10 🪙')).toBeInTheDocument();
    });

    it('calls addToCart when button is clicked', () => {
        render(
            <SnackCard 
                snack={mockSnack} 
                addToCart={mockAddToCart} 
                isHidden={false} 
                hasDiscovered={false} 
                onDiscover={mockOnDiscover} 
            />
        );

        const button = screen.getByText('ADD TO PACK +');
        fireEvent.click(button);
        expect(mockAddToCart).toHaveBeenCalledWith(mockSnack);
    });

    it('triggers discovery on hover when hidden', () => {
        vi.useFakeTimers();
        render(
            <SnackCard 
                snack={mockSnack} 
                addToCart={mockAddToCart} 
                isHidden={true} 
                hasDiscovered={false} 
                onDiscover={mockOnDiscover} 
            />
        );

        const card = screen.getByText('Chips').closest('.brutal-card');
        
        // Simulating hover
        fireEvent.mouseEnter(card);

        // Advance time by 1.6s (threshold is 1.5s)
        act(() => {
            vi.advanceTimersByTime(1600);
        });

        // Resolve deferred updates
        act(() => {
            vi.runAllTimers();
        });

        expect(mockOnDiscover).toHaveBeenCalled();
        vi.useRealTimers();
    });
});
