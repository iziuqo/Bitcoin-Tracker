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

## Files Description

- `bitcoin_tracker.py`: Main script that fetches data and processes technical indicators
- `bitcoin_tracker.yml`: GitHub Actions workflow configuration
- `requirements.txt`: Python dependencies
- `setup.sh`: Setup script to create project structure
- `.gitignore`: Specifies which files Git should ignore

## Dependencies

- Python 3.11+
- Required Python packages (installed automatically):
  - requests==2.31.0
  - pandas==2.1.4
  - numpy==1.26.2
  - sendgrid==6.10.0
  - python-dotenv==1.0.0

## Local Development

While this project is designed to run as a GitHub Action, you can test it locally:

1. Create a `.env` file with your credentials:
```
SENDGRID_API_KEY=your_api_key
FROM_EMAIL=your_verified_sender@email.com
TO_EMAIL=your_recipient@email.com
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the script:
```bash
python src/bitcoin_tracker.py
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This tool is for informational purposes only. It is not financial advice, and the signals it generates should not be used as the sole basis for trading decisions.
