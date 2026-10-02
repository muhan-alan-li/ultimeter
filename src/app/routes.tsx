import { Link, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { TeamListPage } from '../views/teams/TeamListPage';
import { TeamPage } from '../views/teams/TeamPage';
import { GamePage } from '../views/games/GamePage';
import { PointPage } from '../views/points/PointPage';
import { Empty } from '../views/shared';

export function AppRoutes() {
    const { pathname } = useLocation();

    return (
        <Routes key={pathname}>
            <Route path="/" element={<Navigate to="/teams" replace />} />
            <Route path="/teams" element={<TeamListPage />} />
            <Route path="/teams/:teamId" element={<TeamPage />} />
            <Route path="/teams/:teamId/roster" element={<TeamPage />} />
            <Route path="/teams/:teamId/games" element={<TeamPage />} />
            <Route path="/games/:gameId" element={<GamePage />} />
            <Route path="/games/:gameId/points/:pointId" element={<PointPage />} />
            <Route
                path="*"
                element={
                    <main className="page">
                        <Empty title="Page not found">
                            <Link to="/teams">Return to teams</Link>
                        </Empty>
                    </main>
                }
            />
        </Routes>
    );
}
