#!/bin/bash

# Create project directory structure
mkdir -p .github/workflows
mkdir -p src

# Create main Python script
cat > src/bitcoin_tracker.py << 'EOL'
import os
import requests
import pandas as pd
import numpy as np
from datetime import datetime
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def fetch_binance_data():
    endpoint = "https://api.binance.com/api/v3/klines"
    params = {
        "symbol": "BTCUSDT",
        "interval": "15m",
        "limit": 200  # Get enough data for 200MA
    }
    response = requests.get(endpoint, params=params)
    data = response.json()
    
    df = pd.DataFrame(data, columns=[
        'timestamp', 'open', 'high', 'low', 'close', 'volume',
        'close_time', 'quote_volume', 'trades', 'taker_buy_volume',
        'taker_buy_quote_volume', 'ignored'
    ])
    
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    df = df.astype({
        'open': float, 'high': float, 'low': float,
        'close': float, 'volume': float
    })
    return df

def calculate_indicators(df):
    # Calculate Moving Averages
    df['MA20'] = df['close'].rolling(window=20).mean()
    df['MA50'] = df['close'].rolling(window=50).mean()
    df['MA200'] = df['close'].rolling(window=200).mean()
    
    # Calculate Average Volume
    df['avg_volume'] = df['volume'].rolling(window=20).mean()
    
    # Calculate Stochastic
    period = 14
    k_period = 3
    d_period = 3
    
    # Regular Stochastic
    low_min = df['low'].rolling(window=period).min()
    high_max = df['high'].rolling(window=period).max()
    df['K'] = 100 * ((df['close'] - low_min) / (high_max - low_min))
    df['D'] = df['K'].rolling(window=d_period).mean()
    
    # RSI calculation for RSI Stochastic
    delta = df['close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
    rs = gain / loss
    df['RSI'] = 100 - (100 / (1 + rs))
    
    # RSI Stochastic
    rsi_low_min = df['RSI'].rolling(window=period).min()
    rsi_high_max = df['RSI'].rolling(window=period).max()
    df['RSI_K'] = 100 * ((df['RSI'] - rsi_low_min) / (rsi_high_max - rsi_low_min))
    df['RSI_D'] = df['RSI_K'].rolling(window=d_period).mean()
    
    return df

def check_conditions(df):
    latest = df.iloc[-1]
    prev = df.iloc[-2]
    
    conditions = {
        'price_above_ma20': latest['close'] > latest['MA20'] and prev['close'] <= prev['MA20'],
        'price_above_ma50': latest['close'] > latest['MA50'],
        'price_above_ma200': latest['close'] > latest['MA200'],
        'volume_above_average': latest['volume'] > latest['avg_volume'],
        'stoch_k_above_d': latest['K'] > latest['D'],
        'rsi_stoch_k_above_d': latest['RSI_K'] > latest['RSI_D']
    }
    
    return all(conditions.values()), conditions

def send_email_alert(conditions):
    sg = SendGridAPIClient(os.environ['SENDGRID_API_KEY'])
    
    current_price = conditions['current_price']
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
    
    html_content = f"""
    <h2>Bitcoin Trading Signal Alert</h2>
    <p>Timestamp: {timestamp}</p>
    <p>Current BTC Price: ${current_price:.2f}</p>
    <h3>Conditions Met:</h3>
    <ul>
        <li>Price crossed above MA20 ✅</li>
        <li>Price above MA50 ✅</li>
        <li>Price above MA200 ✅</li>
        <li>Volume above average ✅</li>
        <li>Stochastic K above D ✅</li>
        <li>RSI Stochastic K above D ✅</li>
    </ul>
    """
    
    message = Mail(
        from_email=os.environ['FROM_EMAIL'],
        to_emails=os.environ['TO_EMAIL'],
        subject='Bitcoin Trading Signal Alert',
        html_content=html_content
    )
    
    sg.send(message)

def main():
    try:
        df = fetch_binance_data()
        df = calculate_indicators(df)
        
        signal_triggered, conditions = check_conditions(df)
        
        if signal_triggered:
            conditions['current_price'] = df.iloc[-1]['close']
            send_email_alert(conditions)
            print("Alert sent successfully!")
        else:
            print("No signal triggered.")
            
    except Exception as e:
        print(f"Error occurred: {str(e)}")

if __name__ == "__main__":
    main()
EOL

# Create requirements.txt
cat > requirements.txt << 'EOL'
requests==2.31.0
pandas==2.1.4
numpy==1.26.2
sendgrid==6.10.0
python-dotenv==1.0.0
EOL

# Create GitHub Action workflow
cat > .github/workflows/bitcoin_tracker.yml << 'EOL'
name: Bitcoin Price Tracker

on:
  schedule:
    - cron: '*/15 * * * *'  # Run every 15 minutes
  workflow_dispatch:  # Allow manual triggers

jobs:
  check_bitcoin:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        
    - name: Run Bitcoin tracker
      env:
        SENDGRID_API_KEY: ${{ secrets.SENDGRID_API_KEY }}
        FROM_EMAIL: ${{ secrets.FROM_EMAIL }}
        TO_EMAIL: ${{ secrets.TO_EMAIL }}
      run: python src/bitcoin_tracker.py
EOL

# Make setup script executable
chmod +x setup.sh

# Create .gitignore
cat > .gitignore << 'EOL'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
env/
ENV/
.env

# IDE
.idea/
.vscode/
*.swp
*.swo
.project
.pydevproject
.settings/

# Operating System
.DS_Store
Thumbs.db
*.log

# Project specific
*.csv
*.json
temp/
logs/
EOL

# Create README.md
cat > README.md << 'EOL'
# Bitcoin Technical Analysis Tracker

This project monitors Bitcoin price action on the 15-minute timeframe and sends email alerts when specific technical conditions are met.

## Technical Conditions Monitored

The tracker sends an alert when ALL of the following conditions are met:
- Price crosses above the 20 EMA
- Price is above the 50 MA
- Price is above the 200 MA
- Current volume is above the 20-period average volume
- Stochastic oscillator's K line is above D line (bullish)
- RSI Stochastic's K line is above D line (bullish)

## Setup Instructions

1. Clone this repository
2. Set up your GitHub repository secrets:
   - `SENDGRID_API_KEY`: Your SendGrid API key
   - `FROM_EMAIL`: Verified sender email address in SendGrid
   - `TO_EMAIL`: Email address where you want to receive alerts

3. Enable GitHub Actions in your repository settings

## Project Structure

```
.
├── .github
│   └── workflows
│       └── bitcoin_tracker.yml
├── src
│   └── bitcoin_tracker.py
├── requirements.txt
├── README.md
├── .gitignore
└── setup.sh
```

For more details, including local development instructions and contribution guidelines, please refer to the full documentation.
EOL

echo "Setup complete! Project structure has been created."
echo "Next steps:"
echo "1. Add your SendGrid API key to GitHub repository secrets as SENDGRID_API_KEY"
echo "2. Add your sender email to GitHub repository secrets as FROM_EMAIL"
echo "3. Add your recipient email to GitHub repository secrets as TO_EMAIL"
echo "4. Push the code to GitHub"
echo "5. Enable GitHub Actions in your repository"
