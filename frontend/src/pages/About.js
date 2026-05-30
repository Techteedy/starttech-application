import React from 'react';
import './About.css';

function About() {
  return (
    <div className="about">
      <h1>About StartTech</h1>
      <p className="subtitle">
        This project demonstrates a production-grade CI/CD pipeline on AWS using modern DevOps practices.
      </p>

      <div className="info-grid">
        <div className="info-card">
          <h3>🏗 Infrastructure</h3>
          <ul>
            <li>Terraform for Infrastructure as Code</li>
            <li>AWS EC2 with Auto Scaling Groups</li>
            <li>Application Load Balancer</li>
            <li>S3 + CloudFront for frontend</li>
            <li>ElastiCache Redis for caching</li>
            <li>MongoDB Atlas for data</li>
          </ul>
        </div>

        <div className="info-card">
          <h3>🔄 CI/CD Pipeline</h3>
          <ul>
            <li>GitHub Actions workflows</li>
            <li>Automated testing on every push</li>
            <li>Docker image builds & ECR push</li>
            <li>Rolling deployments to EC2</li>
            <li>CloudFront cache invalidation</li>
            <li>Slack/email notifications</li>
          </ul>
        </div>

        <div className="info-card">
          <h3>📊 Monitoring</h3>
          <ul>
            <li>CloudWatch centralized logging</li>
            <li>Custom dashboards & alarms</li>
            <li>Application health checks</li>
            <li>Auto-scaling metrics</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default About;
