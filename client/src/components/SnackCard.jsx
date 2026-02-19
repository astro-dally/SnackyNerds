import { useState, useEffect, useRef } from 'react';

/**
 * SnackCard - Individual snack with Snack Hunt discovery mechanic
 */
const SnackCard = ({ snack, addToCart, isHidden, hasDiscovered, onDiscover }) => {
  const [hoverTime, setHoverTime] = useState(0);
  const [discovered, setDiscovered] = useState(false);
  const timerRef = useRef(null);

  const handleMouseEnter = () => {
    if (!isHidden || hasDiscovered || discovered) return;
    
    // Clear any existing interval just in case
    if (timerRef.current) clearInterval(timerRef.current);

    timerRef.current = setInterval(() => {
      setHoverTime(prev => prev + 100);
    }, 100);
  };

  const handleMouseLeave = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (!discovered) {
      setHoverTime(0);
    }
  };

  // Trigger discovery when hover time reaches threshold
  useEffect(() => {
    if (hoverTime >= 1500 && !discovered && isHidden && !hasDiscovered) {
      setDiscovered(true);
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      // Defer the parent state update to avoid render-time updates
      setTimeout(() => onDiscover(), 0);
    }
  }, [hoverTime, discovered, isHidden, hasDiscovered, onDiscover]);

  // Clean up interval on unmount
  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  // Determine card class based on hunt state
  let huntClass = '';
  if (isHidden && !hasDiscovered && !discovered) {
    huntClass = 'snack-hunt-target';
  } else if (discovered) {
    huntClass = 'snack-hunt-discovered';
  } else if (isHidden && hasDiscovered) {
    huntClass = 'snack-hunt-claimed';
  }

  return (
    <div 
      className={`brutal-card snack-card ${huntClass}`}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <div className="snack-card-emoji">{snack.emoji}</div>
      <h3 className="snack-card-name">{snack.name}</h3>
      <p>{snack.description}</p>
      <span className="snack-card-price">{snack.price.toFixed(0)} 🪙</span>
      <button 
        className="brutal-btn w-full"
        style={{ marginTop: '1rem', width: '100%' }}
        onClick={() => addToCart(snack)}
      >
        ADD TO PACK +
      </button>
    </div>
  );
};

export default SnackCard;
