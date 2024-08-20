document.getElementById('netWorthForm').addEventListener('submit', async function(event) {
    event.preventDefault();
    
    const email = document.getElementById('userEmail').value;
    
    try {
        const response = await axios.post('http://localhost:5000/check-net-worth', { email });
        const result = response.data;

        if (result.access === "denied") {
            document.getElementById('eligibilityResult').innerText = `Access Denied: Your net worth is $${result.net_worth}`;
            // Optionally, you can disable the form or redirect the user
            document.getElementById('deployForm').style.display = 'none';
        } else {
            document.getElementById('eligibilityResult').innerText = `Access Granted: Your net worth is $${result.net_worth}`;
            // Allow the user to proceed
            document.getElementById('deployForm').style.display = 'block';
        }
    } catch (error) {
        console.error('Error checking net worth', error);
        document.getElementById('eligibilityResult').innerText = 'Error checking net worth';
    }
});
