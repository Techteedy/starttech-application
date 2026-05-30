import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import Navbar from '../components/Navbar';

describe('Navbar Component', () => {
  const renderNavbar = () =>
    render(
      <MemoryRouter>
        <Navbar />
      </MemoryRouter>
    );

  test('renders the brand name', () => {
    renderNavbar();
    expect(screen.getByText(/StartTech/i)).toBeInTheDocument();
  });

  test('renders Home link', () => {
    renderNavbar();
    expect(screen.getByText('Home')).toBeInTheDocument();
  });

  test('renders About link', () => {
    renderNavbar();
    expect(screen.getByText('About')).toBeInTheDocument();
  });

  test('renders API Status link', () => {
    renderNavbar();
    expect(screen.getByText('API Status')).toBeInTheDocument();
  });
});
