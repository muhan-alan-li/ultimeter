import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { AppProvider } from './app/context';
import { Application } from './app/Application';
import { SessionRepository } from './storage/SessionRepository';
import { sessionQuery } from './storage/queries';
import { InstallStatus } from './views/app/InstallStatus';
import { AppRoutes } from './app/routes';
import './styles/app.css';

const repository = new SessionRepository();
const application = new Application(repository, sessionQuery(repository));

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <BrowserRouter>
            <AppProvider application={application}>
                <div className="app-shell">
                    <AppRoutes />
                    <footer>
                        <InstallStatus />
                    </footer>
                </div>
            </AppProvider>
        </BrowserRouter>
    </StrictMode>,
);
