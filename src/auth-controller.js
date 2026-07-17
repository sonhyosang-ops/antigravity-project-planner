import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL } from './app-constants.js';

export function createAuthController(deps) {
    async function bootstrapAuthenticatedApp() {
        if (deps.getActiveAuthBootstrapPromise()) return deps.getActiveAuthBootstrapPromise();

        const promise = (async () => {
            deps.setRequiresSupabaseHydration(true);
            const initialRoom = await determineInitialRoom();
            await deps.connectToRoom(initialRoom);
            deps.setHasBootstrappedInitialRoom(true);

            const refreshResult = await deps.refreshCurrentRoomFromSupabase();
            if (!refreshResult?.found && await deps.forceSwitchToLatestDocument()) {
                await deps.refreshCurrentRoomFromSupabase();
            }
        })();

        deps.setActiveAuthBootstrapPromise(promise);

        try {
            await promise;
        } finally {
            deps.setActiveAuthBootstrapPromise(null);
        }
    }

    async function sendOtpCode() {
        if (!deps.getSupabase()) return;

        const email = deps.authEmailInput.value.trim();
        if (!email) {
            deps.setAuthMessage('이메일을 입력해 주세요.', 'error');
            return;
        }

        deps.setPendingAuthEmail(email);
        deps.authSendCodeBtn.disabled = true;
        deps.setAuthMessage('로그인 코드를 보내는 중입니다...');

        const { error } = await deps.getSupabase().auth.signInWithOtp({
            email,
            options: {
                shouldCreateUser: true
            }
        });

        deps.authSendCodeBtn.disabled = false;

        if (error) {
            deps.setAuthMessage(`코드 발송 실패: ${error.message}`, 'error');
            return;
        }

        deps.setAuthMessage('이메일로 로그인 코드를 보냈습니다.', 'success');
        deps.authOtpInput.focus();
    }

    async function verifyOtpCode() {
        if (!deps.getSupabase()) return;

        const email = deps.authEmailInput.value.trim() || deps.getPendingAuthEmail();
        const token = deps.authOtpInput.value.trim();

        if (!email || !token) {
            deps.setAuthMessage('이메일과 로그인 코드를 모두 입력해 주세요.', 'error');
            return;
        }

        deps.authVerifyBtn.disabled = true;
        deps.setAuthMessage('코드를 확인하는 중입니다...');

        const { data, error } = await deps.getSupabase().auth.verifyOtp({
            email,
            token,
            type: 'email'
        });

        deps.authVerifyBtn.disabled = false;

        if (error) {
            deps.setAuthMessage(`인증 실패: ${error.message}`, 'error');
            return;
        }

        deps.setCurrentUser(data.user);
        deps.setRequiresSupabaseHydration(true);
        deps.updateAuthUI();
        deps.setAuthMessage('로그인되었습니다. 문서를 불러오는 중입니다.', 'success');

        if (!deps.getHasBootstrappedInitialRoom()) {
            await bootstrapAuthenticatedApp();
        } else {
            await deps.maybeSwitchToLatestDocument();
            const refreshResult = await deps.refreshCurrentRoomFromSupabase();
            if (!refreshResult?.found) {
                const switched = await deps.forceSwitchToLatestDocument();
                if (switched) {
                    await deps.refreshCurrentRoomFromSupabase();
                }
            }
        }

        if (deps.getSharedMap()) {
            const currentData = deps.getCurrentDocumentData();
            if (deps.getSupabaseDocumentId() || deps.documentHasMeaningfulContent(currentData)) {
                await deps.saveCurrentDocumentToSupabase();
            }
        }
    }

    async function logoutSupabase() {
        if (!deps.getSupabase()) return;
        await deps.getSupabase().auth.signOut();
        deps.disconnectCollaboration();
        deps.setCurrentUser(null);
        deps.setSupabaseDocumentId(null);
        deps.updateAuthUI();
        deps.setAuthMessage('로그아웃되었습니다.');
    }

    function initSupabaseAuth() {
        const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
        deps.setSupabase(supabase);
        deps.updateAuthUI();

        deps.authSendCodeBtn.addEventListener('click', sendOtpCode);
        deps.authVerifyBtn.addEventListener('click', verifyOtpCode);
        deps.authLogoutBtn.addEventListener('click', logoutSupabase);

        supabase.auth.onAuthStateChange(async (_event, session) => {
            deps.setCurrentUser(session?.user || null);
            deps.setSupabaseDocumentId(null);
            if (deps.getCurrentUser()) {
                deps.setRequiresSupabaseHydration(true);
            }
            deps.updateAuthUI();
            if (deps.getCurrentUser()) {
                if (!deps.getHasBootstrappedInitialRoom()) {
                    await bootstrapAuthenticatedApp();
                    return;
                }
                await deps.maybeSwitchToLatestDocument();
                const refreshResult = await deps.refreshCurrentRoomFromSupabase();
                if (!refreshResult?.found && await deps.forceSwitchToLatestDocument()) {
                    await deps.refreshCurrentRoomFromSupabase();
                }
            } else if (deps.getHasBootstrappedInitialRoom()) {
                deps.disconnectCollaboration();
            }
        });

        return supabase.auth.getSession().then(async ({ data }) => {
            deps.setCurrentUser(data.session?.user || null);
            if (deps.getCurrentUser()) {
                deps.setRequiresSupabaseHydration(true);
            }
            deps.updateAuthUI();
            if (deps.getCurrentUser() && deps.getHasBootstrappedInitialRoom()) {
                await deps.maybeSwitchToLatestDocument();
                const refreshResult = await deps.refreshCurrentRoomFromSupabase();
                if (!refreshResult?.found && await deps.forceSwitchToLatestDocument()) {
                    await deps.refreshCurrentRoomFromSupabase();
                }
            }
            return deps.getCurrentUser();
        });
    }

    async function determineInitialRoom() {
        const hashedRoom = window.location.hash.slice(1);

        if (deps.getCurrentUser()) {
            if (hashedRoom) {
                const hashedDocument = await deps.findAccessibleDocumentByRoom(hashedRoom);
                if (hashedDocument?.room_id) {
                    deps.setRoomWasAutoGenerated(false);
                    return hashedDocument.room_id;
                }
            }

            const latestDoc = await deps.findLatestAccessibleDocument();
            if (latestDoc?.room_id) {
                deps.setRoomWasAutoGenerated(false);
                window.location.hash = latestDoc.room_id;
                return latestDoc.room_id;
            }
        }

        if (hashedRoom) {
            deps.setRoomWasAutoGenerated(false);
            return hashedRoom;
        }

        const docs = deps.getRecentDocs();
        if (docs.length > 0) {
            deps.setRoomWasAutoGenerated(false);
            window.location.hash = docs[0].id;
            return docs[0].id;
        }

        deps.setRoomWasAutoGenerated(true);
        const generatedRoom = 'doc-' + Math.random().toString(36).substring(2, 9);
        window.location.hash = generatedRoom;
        return generatedRoom;
    }

    return {
        bootstrapAuthenticatedApp,
        sendOtpCode,
        verifyOtpCode,
        logoutSupabase,
        initSupabaseAuth,
        determineInitialRoom
    };
}
