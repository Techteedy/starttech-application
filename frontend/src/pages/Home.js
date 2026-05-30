import React from 'react';
import './Home.css';

function Home() {
  return (
    <div className="home">
      <div className="hero">
        <h1>Welcome to StartTech</h1>
        <p>A modern full-stack application deployed with a complete CI/CD pipeline on AWS.</p>
        <div className="tech-stack">
          <span className="badge">React</span>
          <span className="badge">Golang</span>
          <span className="badge">MongoDB</span>
          <span className="badge">Redis</span>
          <span className="badge">AWS</span>
        </div>
      </div>

      <div className="features">
        <div className="feature-card">
          <h3>⚡ Fast</h3>
          <p>Served via CloudFront CDN for global low-latency access.</p>
        </div>
        <div className="feature-card">
          <h3>🔒 Secure</h3>
          <p>Security scanning on every deployment. Secrets managed safely.</p>
        </div>
        <div className="feature-card">
          <h3>📈 Scalable</h3>
          <p>Auto-scaling EC2 backend handles traffic spikes automatically.</p>
        </div>
      </div>
    </div>
  );
}

export default Home;
