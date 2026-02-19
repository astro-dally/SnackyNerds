// ══════════════════════════════════════════════════════════════════
// SNACKYNERDS v2 - Advanced Multi-Page Snack Experience
// Creative, multi-page, and powered by Snacky Coins 🪙
// ══════════════════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import { Routes, Route, Link, useNavigate } from 'react-router-dom';
import SnackCard from './components/SnackCard';

// ─── UTILITIES ───────────────────────────────────────────────────

const INITIAL_COINS = 50;

/**
 * Persists Snacky Coins in localStorage
 */
const useWallet = () => {
  const [coins, setCoins] = useState(() => {
    const saved = localStorage.getItem('snacky_coins');
    return saved !== null ? parseInt(saved) : INITIAL_COINS;
  });

  useEffect(() => {
    localStorage.setItem('snacky_coins', coins.toString());
  }, [coins]);

  return [coins, setCoins];
};

/**
 * Snack Hunt - Daily hidden snack discovery system
 */
const SNACK_HUNT_REWARD = 15;

const useSnackHunt = (snacks, addCoins) => {
  const [huntState, setHuntState] = useState(() => {
    const saved = localStorage.getItem('snack_hunt');
    return saved ? JSON.parse(saved) : { discovered: false, date: null };
  });
  const [showToast, setShowToast] = useState(false);
  const [justDiscovered, setJustDiscovered] = useState(false);

  // Generate daily hidden snack ID using date-based deterministic hash
  const getHiddenSnackId = () => {
    if (snacks.length === 0) return null;
    const today = new Date().toDateString();
    let hash = 0;
    for (let i = 0; i < today.length; i++) {
      hash = ((hash << 5) - hash) + today.charCodeAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    const index = Math.abs(hash) % snacks.length;
    return snacks[index]?.id;
  };

  const hiddenSnackId = getHiddenSnackId();
  const today = new Date().toDateString();
  const hasDiscoveredToday = huntState.discovered && huntState.date === today;

  // Persist hunt state
  useEffect(() => {
    localStorage.setItem('snack_hunt', JSON.stringify(huntState));
  }, [huntState]);

  // Reset discovery state if it's a new day
  useEffect(() => {
    if (huntState.date && huntState.date !== today) {
      setHuntState({ discovered: false, date: null });
    }
  }, [today, huntState.date]);

  const discoverSnack = () => {
    if (hasDiscoveredToday) return false;
    
    setHuntState({ discovered: true, date: today });
    setJustDiscovered(true);
    setShowToast(true);
    addCoins(SNACK_HUNT_REWARD);

    // Auto-hide toast after 4 seconds
    setTimeout(() => setShowToast(false), 4000);
    
    return true;
  };

  return {
    hiddenSnackId,
    hasDiscoveredToday,
    justDiscovered,
    showToast,
    discoverSnack,
    reward: SNACK_HUNT_REWARD
  };
};

// ─── SHARED COMPONENTS ───────────────────────────────────────────

const Header = ({ cartCount, coins, coinPop }) => (
  <header className="header">
    <Link to="/" className="logo wobble">🍿 SNACKYNERDS</Link>
    <div className="nav-links">
      <div className="snacky-wallet">
        <span className={`coin-bounce ${coinPop ? 'coin-pop' : ''}`}>🪙</span> {coins} COINS
      </div>
      <Link to="/cart">
        <button className="brutal-btn pink">
          🛒 CART ({cartCount})
        </button>
      </Link>
    </div>
  </header>
);

const Marquee = () => (
  <div className="brutal-marquee">
    <div className="marquee-content">
      FREE SHIPPING ON ALL ORDERS OVER 20 COINS! 🍿 DON'T MISS OUT ON THE CHEESE PUFFS RELOAD! 🍕 SNACKY COINS ARE THE FUTURE OF CURRENCY! 🐻 🎯 SNACK HUNT: FIND TODAY'S HIDDEN SNACK FOR BONUS COINS! 🎯
    </div>
  </div>
);

/**
 * Reward Toast - Celebration feedback for Snack Hunt discovery
 */
const RewardToast = ({ show, reward, onHide }) => {
  const [hiding, setHiding] = useState(false);

  useEffect(() => {
    if (show) {
      const hideTimer = setTimeout(() => {
        setHiding(true);
        setTimeout(() => {
          setHiding(false);
          onHide?.();
        }, 400);
      }, 3600);
      return () => clearTimeout(hideTimer);
    }
  }, [show, onHide]);

  if (!show && !hiding) return null;

  return (
    <div className={`reward-toast ${hiding ? 'hide' : ''}`}>
      <div className="reward-title">You found today's Snack Hunt! 🎉</div>
      <div className="reward-coins">
        <span className="coin-icon">🪙</span>
        <span>+{reward} COINS</span>
      </div>
    </div>
  );
};


// ─── PAGES ───────────────────────────────────────────────────────

/**
 * HOME PAGE
 */
const HomePage = ({ snacks, addToCart, snackHunt }) => (
  <div className="container">
    <section className="hero tilted">
      <h2>SNACKS FOR <br/> TRUE NERDS</h2>
      <p>Fuel your brain with our crunchy collection</p>
    </section>

    <div className="snack-grid">
      {snacks.map(snack => (
        <SnackCard
          key={snack.id}
          snack={snack}
          addToCart={addToCart}
          isHidden={snack.id === snackHunt.hiddenSnackId}
          hasDiscovered={snackHunt.hasDiscoveredToday}
          onDiscover={snackHunt.discoverSnack}
        />
      ))}
    </div>
  </div>
);

/**
 * CART PAGE
 */
const CartPage = ({ cart, removeFromCart }) => {
  const total = cart.reduce((sum, item) => sum + item.price * item.qty, 0);

  return (
    <div className="container">
      <h2 className="logo tilted-reverse" style={{ fontSize: '3rem', margin: '2rem 0' }}>YOUR LOOT</h2>
      
      {cart.length === 0 ? (
        <div className="brutal-card" style={{ textAlign: 'center' }}>
          <h3>YOUR PACK IS EMPTY! 😢</h3>
          <Link to="/" className="brutal-btn" style={{ marginTop: '2rem' }}>GO GRAB SNACKS</Link>
        </div>
      ) : (
        <div className="cart-list">
          {cart.map(item => (
            <div key={item.id} className="cart-item">
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <span style={{ fontSize: '3rem' }}>{item.emoji}</span>
                <div>
                  <h4 style={{ textTransform: 'uppercase' }}>{item.name}</h4>
                  <p>{item.qty} UNITS × {item.price} 🪙</p>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <span style={{ fontWeight: 900, fontSize: '1.5rem' }}>{item.price * item.qty} 🪙</span>
                <button className="brutal-btn pink" onClick={() => removeFromCart(item.id)} style={{ padding: '0.5rem 1rem' }}>−</button>
              </div>
            </div>
          ))}
          
          <div className="brutal-card checkout-details tilted" style={{ textAlign: 'right', marginTop: '2rem' }}>
            <h3>TOTAL DAMAGE: {total} 🪙</h3>
            <Link to="/checkout" className="brutal-btn orange" style={{ marginTop: '1rem' }}>PROCEED TO CHECKOUT ➡️</Link>
          </div>
        </div>
      )}
    </div>
  );
};

/**
 * CHECKOUT PAGE
 */
const CheckoutPage = ({ cart, coins, setCoins, setCart }) => {
  const navigate = useNavigate();
  const total = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const canAfford = coins >= total;

  const handlePay = () => {
    if (canAfford) {
      setCoins(coins - total);
      setCart([]);
      navigate('/success');
    }
  };

  if (cart.length === 0) return <Link to="/" />;

  return (
    <div className="container">
      <div className="brutal-card checkout-details">
        <h2 style={{ textTransform: 'uppercase', marginBottom: '2rem' }}>Checkout Breakdown</h2>
        <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>
          <p>WALLET BALANCE: {coins} 🪙</p>
          <p>ORDER TOTAL: {total} 🪙</p>
          <div style={{ borderTop: '4px solid black', margin: '1rem 0', padding: '1rem 0' }}>
            {canAfford ? (
              <p style={{ color: 'green' }}>✓ SUFFICIENT SNACKY COINS DETECTED</p>
            ) : (
              <p style={{ color: 'red' }}>✘ INSUFFICIENT FUNDS! GO HACK SOME MORE COINS.</p>
            )}
          </div>
        </div>
        <button 
          className="brutal-btn cyan" 
          disabled={!canAfford}
          style={{ width: '100%', opacity: canAfford ? 1 : 0.5 }}
          onClick={handlePay}
        >
          {canAfford ? 'INITIALIZE PAYMENT 🪙' : 'ERROR: LOW BALANCE'}
        </button>
      </div>
    </div>
  );
};

/**
 * SUCCESS PAGE
 */
const SuccessPage = () => (
  <div className="container" style={{ marginTop: '4rem' }}>
    <div className="brutal-card success-card tilted">
      <span className="success-icon coin-bounce">🪙✨</span>
      <h2>PAYMENT SUCCESSFUL!</h2>
      <p style={{ fontWeight: 800, margin: '1rem 0' }}>CRUNCHY GOODNESS IS ON THE WAY TO YOUR TERMINAL.</p>
      <Link to="/" className="brutal-btn">SNACK AGAIN</Link>
    </div>
  </div>
);

// ─── MAIN APP COMPONENT ──────────────────────────────────────────

function App() {
  const [snacks, setSnacks] = useState([]);
  const [cart, setCart] = useState([]);
  const [coins, setCoins] = useWallet();
  const [coinPop, setCoinPop] = useState(false);

  // Snack Hunt integration
  const addCoins = (amount) => {
    setCoins(prev => prev + amount);
    setCoinPop(true);
    setTimeout(() => setCoinPop(false), 400);
  };
  
  const snackHunt = useSnackHunt(snacks, addCoins);

  useEffect(() => {
    const apiUrl = import.meta.env.VITE_API_URL || '';
    fetch(`${apiUrl}/api/snacks`)
      .then(res => res.json())
      .then(data => setSnacks(data))
      .catch(err => console.error(err));
  }, []);

  const addToCart = (snack) => {
    setCart(prev => {
      const exists = prev.find(i => i.id === snack.id);
      if (exists) return prev.map(i => i.id === snack.id ? { ...i, qty: i.qty + 1 } : i);
      return [...prev, { ...snack, qty: 1 }];
    });
  };

  const removeFromCart = (id) => {
    setCart(prev => prev.map(i => i.id === id ? { ...i, qty: i.qty - 1 } : i).filter(i => i.qty > 0));
  };

  const cartCount = cart.reduce((s, i) => s + i.qty, 0);

  return (
    <div className="app">
      <Marquee />
      <Header cartCount={cartCount} coins={coins} coinPop={coinPop} />
      <RewardToast show={snackHunt.showToast} reward={snackHunt.reward} />
      
      <Routes>
        <Route path="/" element={<HomePage snacks={snacks} addToCart={addToCart} snackHunt={snackHunt} />} />
        <Route path="/cart" element={<CartPage cart={cart} removeFromCart={removeFromCart} />} />
        <Route path="/checkout" element={<CheckoutPage cart={cart} coins={coins} setCoins={setCoins} setCart={setCart} />} />
        <Route path="/success" element={<SuccessPage />} />
      </Routes>
      
      <footer style={{ textAlign: 'center', padding: '2rem', fontWeight: 900, textTransform: 'uppercase' }}>
        SnackyNerds © 2026 // No Real Money Involved
      </footer>
    </div>
  );
}

export default App;
