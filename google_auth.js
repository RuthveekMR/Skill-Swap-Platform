function handleGoogleLogin() {
  google.accounts.id.initialize({
    client_id: '144575491595-ff9egetl3svgbe6f83rtkggfek27pn3g.apps.googleusercontent.com',
    callback: async (response) => {
      const res = await fetch('/api/auth/google', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: response.credential })
      });
      const data = await res.json();
      if (data.token) {
        localStorage.setItem('token', data.token);
        localStorage.setItem('user', JSON.stringify(data.user));
        window.location.href = 'dashboard.html';
      } else {
        alert('Login failed');
      }
    }
  });
  google.accounts.id.prompt();
}
