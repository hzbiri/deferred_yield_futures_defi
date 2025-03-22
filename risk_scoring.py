// risk_scoring_example.py
import random
from typing import List, Dict

def compute_user_risk_score(
    user_address: str,
    user_history: Dict[str, float],
    protocol_volatility: float,
    suspicious_flag: bool
) -> int:
    print(f"Computing risk score for user {user_address}...")
    score = 0

    if suspicious_flag:
        score += 40

    volatility_score = int(protocol_volatility * 30)
    score += volatility_score

    repayment_rate = user_history.get("repayment_rate", 1.0)
    if repayment_rate < 0.8:
        score += 20
    elif repayment_rate < 0.95:
        score += 10

    total_borrowed = user_history.get("total_borrowed", 0.0)
    if total_borrowed > 50000:
        score += 10
    elif total_borrowed > 20000:
        score += 5

    score += random.randint(0, 5)
    score = min(score, 100)

    return score

if __name__ == "__main__":
    user = "0xUserAddressMock"
    mock_history = {
        "total_borrowed": 30000.0,
        "repayment_rate": 0.9,
        "late_payments": 1.0
    }
    mock_volatility = 0.6
    is_suspicious = False

    final_score = compute_user_risk_score(
        user,
        mock_history,
        protocol_volatility=mock_volatility,
        suspicious_flag=is_suspicious
    )
    print(f"Risk Score for {user}: {final_score}")