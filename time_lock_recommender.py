# time_lock_recommender.py
import random
import statistics

def recommend_lock_duration(protocol: str = "default", apy_history: list = None) -> int:
    print(f"Recommending lock duration for {protocol}...")

    if apy_history is None:
        apy_history = [4.2, 4.3, 3.8, 5.1, 6.0, 4.9, 5.2]  # Mock APY history

    volatility = statistics.stdev(apy_history)
    average_apy = statistics.mean(apy_history)

    if volatility > 1.0:
        recommended_days = 30
    elif average_apy > 5.0:
        recommended_days = 90
    else:
        recommended_days = 60

    return recommended_days * 24 * 60 * 60

if __name__ == "__main__":
    duration = recommend_lock_duration("YieldProtocolX", [4.1, 4.0, 5.2, 6.5, 5.8])
    print(f"Recommended Lock Duration: {duration // (24 * 60 * 60)} days")