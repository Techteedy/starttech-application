import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import Home from '../pages/Home';

describe('Home Page', () => {
  test('renders welcome heading', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(screen.getByText(/Welcome to StartTech/i)).toBeInTheDocument();
  });

  test('renders all tech stack badges', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(screen.getByText('React')).toBeInTheDocument();
    expect(screen.getByText('Golang')).toBeInTheDocument();
    expect(screen.getByText('MongoDB')).toBeInTheDocument();
    expect(screen.getByText('Redis')).toBeInTheDocument();
    expect(screen.getByText('AWS')).toBeInTheDocument();
  });

  test('renders three feature cards', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(screen.getByText(/Fast/i)).toBeInTheDocument();
    expect(screen.getByText(/Secure/i)).toBeInTheDocument();
    expect(screen.getByText(/Scalable/i)).toBeInTheDocument();
  });
});
