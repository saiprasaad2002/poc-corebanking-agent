def get_gl_balance(account_number):
    if account_number == 123:
        return 1000
    else:
        return 0

def get_loan_balance(account_holder):
    if account_holder.lower() == "sai":
        return 500
    else:
        return 0
    
def get_car_ratio():
    return 0.8