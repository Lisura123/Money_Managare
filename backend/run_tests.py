import requests, json, subprocess, sys, os

BASE = "http://127.0.0.1:8000/api"
H = {"Content-Type": "application/json", "Accept": "application/json"}

# ── RESET DB TO KNOWN STATE ───────────────────────────────────────────────────
print("── PRE-TEST: migrate:fresh --seed ──")
proc = subprocess.run(
    ["php", "artisan", "migrate:fresh", "--seed", "--force"],
    cwd=os.path.dirname(os.path.abspath(__file__)),
    capture_output=True, text=True, timeout=60
)
if proc.returncode != 0:
    print("  [ERROR] Reseed failed:")
    print(proc.stderr[:500])
    sys.exit(1)
print("  DB reseeded OK")

results = []
v = {}  # shared state: tokens, IDs

def auth(tok_key="token"):
    return {**H, "Authorization": f"Bearer {v.get(tok_key, '')}"}

def r(method, path, **kwargs):
    url = BASE + path
    return requests.request(method, url, timeout=15, **kwargs)

def data_list(body):
    if isinstance(body, list):
        return body
    if isinstance(body, dict):
        d = body.get("data", [])
        if isinstance(d, list):
            return d
    return []

def data_item(body):
    if isinstance(body, dict) and "data" in body and isinstance(body["data"], dict):
        return body["data"]
    if isinstance(body, dict) and "id" in body:
        return body
    return body if isinstance(body, dict) else {}

def test(num, name, method, path, expected_status, check_fn=None, tok=None, **kwargs):
    headers = auth(tok) if tok else H
    try:
        resp = r(method, path, headers=headers, **kwargs)
        status = resp.status_code
        try:
            body = resp.json()
        except Exception:
            body = resp.text[:300]
        passed = status == expected_status
        if passed and check_fn:
            try:
                result = check_fn(body, resp)
                if result is False:
                    passed = False
            except Exception as e:
                passed = False
                body = f"check_fn raised: {e} | body: {body}"
        symbol = "PASS" if passed else "FAIL"
        results.append((num, name, method.upper(), expected_status, status, symbol))
        if not passed:
            print(f"  [FAIL] #{num} {name} => expected {expected_status} got {status}")
            print(f"         body: {str(body)[:500]}")
        else:
            print(f"  [PASS] #{num} {name} => {status}")
        return resp, body, passed
    except Exception as e:
        results.append((num, name, method.upper(), expected_status, "ERR", "FAIL"))
        print(f"  [FAIL] #{num} {name} => exception: {e}")
        return None, None, False

print("=" * 70)
print("MONEY MANAGER API — FULL TEST RUN (post-fix)")
print("=" * 70)

# ── PHASE 1: AUTH ─────────────────────────────────────────────────────────────
print("\n── PHASE 1: AUTHENTICATION ──")

resp, body, ok = test(1, "Admin login", "POST", "/login", 200,
    lambda b, r: bool(b.get("token")),
    json={"email": "admin@admin.com", "password": "password"})
if ok:
    v["token"] = body["token"]

resp, body, ok = test(2, "Staff login", "POST", "/login", 200,
    lambda b, r: bool(b.get("token")),
    json={"email": "staff.downtown@example.com", "password": "password"})
if ok:
    v["staff_token"] = body["token"]

resp, body, ok = test(3, "Forgot password (get dev_code)", "POST", "/forgot-password", 200,
    lambda b, r: "dev_code" in b,
    json={"email": "admin@admin.com"})
if ok:
    v["reset_code"] = body.get("dev_code", "")

resp, body, ok = test(4, "Reset password", "POST", "/reset-password", 200,
    json={"email": "admin@admin.com", "code": v.get("reset_code", ""),
          "password": "newpassword", "password_confirmation": "newpassword"})

resp, body, ok = test(5, "Login with new password", "POST", "/login", 200,
    lambda b, r: bool(b.get("token")),
    json={"email": "admin@admin.com", "password": "newpassword"})
if ok:
    v["token"] = body["token"]

resp, body, ok = test(6, "Logout (revoke old token)", "POST", "/logout", 200, tok="token")

resp, body, ok = test(7, "Re-login admin (fresh token)", "POST", "/login", 200,
    lambda b, r: bool(b.get("token")),
    json={"email": "admin@admin.com", "password": "newpassword"})
if ok:
    v["token"] = body["token"]

# ── PHASE 2: STAFF OPERATIONS ─────────────────────────────────────────────────
print("\n── PHASE 2: STAFF OPERATIONS ──")

resp, body, ok = test(8, "Staff: GET /my-card-accounts", "GET", "/my-card-accounts", 200,
    lambda b, r: len(data_list(b)) > 0, tok="staff_token")
if ok:
    items = data_list(body)
    v["card_account_id"] = items[0]["id"]
    v["card_balance_before"] = float(items[0].get("current_balance", 0))
    print(f"       card_account_id={v['card_account_id']}, balance={v['card_balance_before']}")

resp, body, ok = test(9, "Staff: POST /cash-entries", "POST", "/cash-entries", 201,
    tok="staff_token",
    json={"entry_date": "2026-04-11", "cash_amount": 75000, "notes": "Test cash entry"})
if ok:
    item = data_item(body)
    v["cash_entry_id"] = item.get("id")
    print(f"       cash_entry_id={v['cash_entry_id']}")

resp, body, ok = test(10, "Staff: GET /cash-entries/my-history", "GET", "/cash-entries/my-history", 200,
    lambda b, r: len(data_list(b)) > 0, tok="staff_token")

resp, body, ok = test(11, "Staff: POST /card-entries", "POST", "/card-entries", 201,
    tok="staff_token",
    json={"entry_date": "2026-04-11", "card_account_id": v.get("card_account_id"),
          "amount": 45000, "notes": "Test card entry"})
if ok:
    item = data_item(body)
    v["card_entry_id"] = item.get("id")
    print(f"       card_entry_id={v['card_entry_id']}")

resp, body, ok = test(12, "Staff: GET /card-entries/my-history", "GET", "/card-entries/my-history", 200,
    lambda b, r: len(data_list(b)) > 0, tok="staff_token")

resp, body, ok = test(13, "Staff: Card balance increased by 45000", "GET", "/my-card-accounts", 200,
    lambda b, r: abs(float(data_list(b)[0].get("current_balance", 0)) - (v.get("card_balance_before", 0) + 45000)) < 1,
    tok="staff_token")

resp, body, ok = test(14, "Staff cannot POST /showrooms (403)", "POST", "/showrooms", 403,
    tok="staff_token", json={"name": "Unauthorized"})

# ── PHASE 3: ADMIN SHOWROOM CRUD ──────────────────────────────────────────────
print("\n── PHASE 3: ADMIN SHOWROOM CRUD ──")

resp, body, ok = test(15, "Admin: GET /showrooms (>=3 seeded)", "GET", "/showrooms", 200,
    lambda b, r: len(data_list(b)) >= 3, tok="token")
if ok:
    v["showroom_id"] = data_list(body)[0]["id"]
    print(f"       showroom_id={v['showroom_id']}")

resp, body, ok = test(16, "Admin: POST /showrooms", "POST", "/showrooms", 201, tok="token",
    json={"name": "Westside Showroom", "location": "45 West Ave"})
if ok:
    v["new_showroom_id"] = data_item(body).get("id")
    print(f"       new_showroom_id={v['new_showroom_id']}")

resp, body, ok = test(17, "Admin: GET /showrooms/{id} verify name", "GET",
    f"/showrooms/{v.get('new_showroom_id')}", 200,
    lambda b, r: data_item(b).get("name") == "Westside Showroom", tok="token")

resp, body, ok = test(18, "Admin: PUT /showrooms/{id}", "PUT",
    f"/showrooms/{v.get('new_showroom_id')}", 200, tok="token",
    json={"name": "Westside Premium", "location": "45 West Ave"})

resp, body, ok = test(19, "Admin: DELETE /showrooms/{id}", "DELETE",
    f"/showrooms/{v.get('new_showroom_id')}", 200, tok="token")

resp, body, ok = test(20, "Admin: GET deleted showroom = 404", "GET",
    f"/showrooms/{v.get('new_showroom_id')}", 404, tok="token")

# ── PHASE 4: ADMIN CARD ACCOUNT CRUD ─────────────────────────────────────────
print("\n── PHASE 4: ADMIN CARD ACCOUNT CRUD ──")

resp, body, ok = test(21, "Admin: GET card-accounts (>=2 seeded)", "GET",
    f"/showrooms/{v.get('showroom_id')}/card-accounts", 200,
    lambda b, r: len(data_list(b)) >= 2, tok="token")

resp, body, ok = test(22, "Admin: POST card-account", "POST",
    f"/showrooms/{v.get('showroom_id')}/card-accounts", 201, tok="token",
    json={"bank_name": "Test Bank", "last_four": "9999", "current_balance": 100000})
if ok:
    v["new_card_id"] = data_item(body).get("id")
    print(f"       new_card_id={v['new_card_id']}")

resp, body, ok = test(23, "Admin: GET card-account", "GET",
    f"/showrooms/{v.get('showroom_id')}/card-accounts/{v.get('new_card_id')}", 200, tok="token")

resp, body, ok = test(24, "Admin: PUT card-account", "PUT",
    f"/showrooms/{v.get('showroom_id')}/card-accounts/{v.get('new_card_id')}", 200, tok="token",
    json={"bank_name": "Updated Bank", "last_four": "9999", "current_balance": 150000})

resp, body, ok = test(25, "Admin: DELETE card-account", "DELETE",
    f"/showrooms/{v.get('showroom_id')}/card-accounts/{v.get('new_card_id')}", 200, tok="token")

# ── PHASE 5: ADMIN STAFF MANAGEMENT ──────────────────────────────────────────
print("\n── PHASE 5: ADMIN STAFF MANAGEMENT ──")

resp, body, ok = test(26, "Admin: GET /staff (>=3 seeded)", "GET", "/staff", 200,
    lambda b, r: len(data_list(b)) >= 3, tok="token")

resp, body, ok = test(27, "Admin: POST /staff", "POST", "/staff", 201, tok="token",
    json={"name": "Test User", "email": "test@example.com", "password": "password",
          "password_confirmation": "password", "showroom_id": v.get("showroom_id")})
if ok:
    v["new_staff_id"] = data_item(body).get("id")
    print(f"       new_staff_id={v['new_staff_id']}")

resp, body, ok = test(28, "Admin: GET /staff/{id}", "GET",
    f"/staff/{v.get('new_staff_id')}", 200, tok="token")

resp, body, ok = test(29, "Admin: PUT /staff (deactivate)", "PUT",
    f"/staff/{v.get('new_staff_id')}", 200, tok="token",
    json={"name": "Updated User", "is_active": False})

resp, body, ok = test(30, "Deactivated user login = 403", "POST", "/login", 403,
    json={"email": "test@example.com", "password": "password"})

resp, body, ok = test(31, "Admin: DELETE /staff/{id}", "DELETE",
    f"/staff/{v.get('new_staff_id')}", 200, tok="token")

# ── PHASE 6: ADMIN CASH ENTRY OPERATIONS ─────────────────────────────────────
print("\n── PHASE 6: ADMIN CASH ENTRY OPERATIONS ──")

resp, body, ok = test(32, "Admin: GET /cash-entries (all)", "GET", "/cash-entries", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

resp, body, ok = test(33, "Admin: GET /cash-entries?showroom_id=", "GET",
    f"/cash-entries?showroom_id={v.get('showroom_id')}", 200, tok="token")

resp, body, ok = test(34, "Admin: GET /cash-entries?date=", "GET",
    "/cash-entries?date=2026-04-11", 200, tok="token")

resp, body, ok = test(35, "Admin: GET /cash-entries?from&to", "GET",
    "/cash-entries?from=2026-04-01&to=2026-04-11", 200, tok="token")

resp, body, ok = test(36, "Admin: PUT /cash-entries/{id}", "PUT",
    f"/cash-entries/{v.get('cash_entry_id')}", 200, tok="token",
    json={"cash_amount": 80000, "notes": "Admin corrected"})

resp, body, ok = test(37, "Admin: POST cash-entry adjustment", "POST",
    f"/cash-entries/{v.get('cash_entry_id')}/adjustments", 201, tok="token",
    json={"adjustment_amount": -5000, "reason": "Cash count discrepancy"})

resp, body, ok = test(38, "Admin: GET cash-entry adjustments (>=1)", "GET",
    f"/cash-entries/{v.get('cash_entry_id')}/adjustments", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

resp, body, ok = test(39, "Admin: POST /cash-entries/lock-old", "POST",
    "/cash-entries/lock-old", 200, tok="token")

# ── PHASE 7: ADMIN CARD ENTRY OPERATIONS ─────────────────────────────────────
print("\n── PHASE 7: ADMIN CARD ENTRY OPERATIONS ──")

resp, body, ok = test(40, "Admin: GET /card-entries (all)", "GET", "/card-entries", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

resp, body, ok = test(41, "Admin: GET /card-entries?showroom_id=", "GET",
    f"/card-entries?showroom_id={v.get('showroom_id')}", 200, tok="token")

pre_update_resp = requests.get(
    f"{BASE}/showrooms/{v.get('showroom_id')}/card-accounts",
    headers=auth("token")).json()
pre_update_balance = next((float(c["current_balance"]) for c in data_list(pre_update_resp)
                           if c["id"] == v.get("card_account_id")), None)

resp, body, ok = test(42, "Admin: PUT /card-entries/{id} amount=50000", "PUT",
    f"/card-entries/{v.get('card_entry_id')}", 200, tok="token",
    json={"amount": 50000, "notes": "Admin adjusted"})

post_update_resp = requests.get(
    f"{BASE}/showrooms/{v.get('showroom_id')}/card-accounts",
    headers=auth("token")).json()
post_update_balance = next((float(c["current_balance"]) for c in data_list(post_update_resp)
                            if c["id"] == v.get("card_account_id")), None)
if pre_update_balance is not None and post_update_balance is not None:
    balance_diff = post_update_balance - pre_update_balance
    balance_ok = abs(balance_diff - 5000) < 1
    symbol = "PASS" if balance_ok else "FAIL"
    results.append((42.1, "Card balance recalculated after update (+5000)", "GET",
                    200, 200 if balance_ok else 0, symbol))
    print(f"  [{symbol}] #42.1 Balance recalculated: pre={pre_update_balance}, post={post_update_balance}, diff={balance_diff:.2f}")

resp, body, ok = test(43, "Admin: POST card-entry adjustment", "POST",
    f"/card-entries/{v.get('card_entry_id')}/adjustments", 201, tok="token",
    json={"adjustment_amount": 2000, "reason": "Settlement difference"})

resp, body, ok = test(44, "Admin: GET card-entry adjustments (>=1)", "GET",
    f"/card-entries/{v.get('card_entry_id')}/adjustments", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

resp, body, ok = test(45, "Admin: POST /card-entries/lock-old", "POST",
    "/card-entries/lock-old", 200, tok="token")

# ── PHASE 8: SELF-TRANSACTIONS ────────────────────────────────────────────────
print("\n── PHASE 8: SELF-TRANSACTIONS ──")

resp, body, ok = test(46, "Admin: GET showroom 1 card accounts", "GET",
    f"/showrooms/{v.get('showroom_id')}/card-accounts", 200, tok="token")
if ok:
    items = data_list(body)
    if items:
        v["from_card_id"] = items[0]["id"]
        v["from_card_balance"] = float(items[0].get("current_balance", 0))
        print(f"       from_card={v['from_card_id']}, balance={v['from_card_balance']}")

showrooms_all = requests.get(f"{BASE}/showrooms", headers=auth("token")).json()
other_showroom = next((s for s in data_list(showrooms_all) if s["id"] != v.get("showroom_id")), None)
v["other_showroom"] = other_showroom
if other_showroom:
    other_cards = requests.get(f"{BASE}/showrooms/{other_showroom['id']}/card-accounts",
                               headers=auth("token")).json()
    other_items = data_list(other_cards)
    if other_items:
        v["to_card_id"] = other_items[0]["id"]
        v["to_card_balance"] = float(other_items[0].get("current_balance", 0))
        print(f"       to_card={v['to_card_id']}, balance={v['to_card_balance']}, showroom={other_showroom['id']}")

resp, body, ok = test(47, "Admin: POST /self-transactions", "POST", "/self-transactions", 201,
    tok="token",
    json={"from_card_account_id": v.get("from_card_id"),
          "to_card_account_id": v.get("to_card_id"),
          "amount": 10000, "notes": "Supplier payment transfer"})

from_cards = requests.get(f"{BASE}/showrooms/{v.get('showroom_id')}/card-accounts",
                          headers=auth("token")).json()
from_new = next((float(c["current_balance"]) for c in data_list(from_cards)
                 if c["id"] == v.get("from_card_id")), None)
to_new = None
if other_showroom:
    to_cards = requests.get(f"{BASE}/showrooms/{other_showroom['id']}/card-accounts",
                            headers=auth("token")).json()
    to_new = next((float(c["current_balance"]) for c in data_list(to_cards)
                   if c["id"] == v.get("to_card_id")), None)

from_ok = from_new is not None and abs(from_new - (v.get("from_card_balance", 0) - 10000)) < 1
to_ok = to_new is not None and abs(to_new - (v.get("to_card_balance", 0) + 10000)) < 1
b_ok = from_ok and to_ok
sym = "PASS" if b_ok else "FAIL"
results.append((48, "Self-tx: from -10000, to +10000 verified", "GET", 200, 200 if b_ok else 0, sym))
print(f"  [{sym}] #48 from={from_new} (expect {v.get('from_card_balance',0)-10000:.2f}), "
      f"to={to_new} (expect {v.get('to_card_balance',0)+10000:.2f})")

resp, body, ok = test(49, "Admin: GET /self-transactions (>=1)", "GET", "/self-transactions", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

# ── PHASE 9: SETTINGS ─────────────────────────────────────────────────────────
print("\n── PHASE 9: SETTINGS ──")

resp, body, ok = test(50, "Admin: GET /settings (lock_hours exists)", "GET", "/settings", 200,
    lambda b, r: any(s.get("key") == "lock_hours" for s in data_list(b)), tok="token")
if ok:
    setting = next((s for s in data_list(body) if s.get("key") == "lock_hours"), None)
    if setting:
        v["setting_id"] = setting["id"]
        print(f"       setting_id={v['setting_id']}")

resp, body, ok = test(51, "Admin: PUT /settings/{id} value=48", "PUT",
    f"/settings/{v.get('setting_id')}", 200, tok="token",
    json={"value": "48"})

resp, body, ok = test(52, "Admin: GET /settings confirms value=48", "GET", "/settings", 200,
    lambda b, r: any(str(s.get("value")) == "48" for s in data_list(b)), tok="token")

# ── PHASE 10: AUDIT LOGS ──────────────────────────────────────────────────────
print("\n── PHASE 10: AUDIT LOGS ──")

resp, body, ok = test(53, "Admin: GET /audit-logs (has entries)", "GET", "/audit-logs", 200,
    lambda b, r: len(data_list(b)) > 0, tok="token")

resp, body, ok = test(54, "Admin: GET /audit-logs?table_name=daily_cash_entries", "GET",
    "/audit-logs?table_name=daily_cash_entries", 200, tok="token")

resp, body, ok = test(55, "Admin: GET /audit-logs?action=created", "GET",
    "/audit-logs?action=created", 200, tok="token")

resp, body, ok = test(56, "Admin: GET /audit-logs?user_id=1", "GET",
    "/audit-logs?user_id=1", 200, tok="token")

# ── PHASE 11: PDF REPORTS ─────────────────────────────────────────────────────
print("\n── PHASE 11: PDF REPORTS ──")

def is_pdf(b, resp):
    ct = resp.headers.get("Content-Type", "")
    return "pdf" in ct.lower() and len(resp.content) > 1000

resp, body, ok = test(57, "PDF: daily-summary", "GET",
    "/reports/pdf/daily-summary?date=2026-04-11", 200, check_fn=is_pdf, tok="token")

resp, body, ok = test(58, "PDF: showroom report", "GET",
    f"/reports/pdf/showroom?showroom_id={v.get('showroom_id')}&from=2026-04-01&to=2026-04-11",
    200, check_fn=is_pdf, tok="token")

resp, body, ok = test(59, "PDF: card-statement", "GET",
    f"/reports/pdf/card-statement?card_account_id={v.get('card_account_id')}&from=2026-04-01&to=2026-04-11",
    200, check_fn=is_pdf, tok="token")

resp, body, ok = test(60, "PDF: self-transactions", "GET",
    "/reports/pdf/self-transactions?from=2026-04-01&to=2026-04-11", 200, check_fn=is_pdf, tok="token")

resp, body, ok = test(61, "PDF: adjustments", "GET",
    "/reports/pdf/adjustments?from=2026-04-01&to=2026-04-11", 200, check_fn=is_pdf, tok="token")

# ── PHASE 12: EDGE CASES ──────────────────────────────────────────────────────
print("\n── PHASE 12: EDGE CASES ──")

resp, body, ok = test(62, "Validation: missing cash_amount = 422", "POST",
    "/cash-entries", 422, tok="staff_token",
    json={"entry_date": "2026-04-11", "notes": "missing amount"})

v["other_showroom_card_id"] = None
if other_showroom:
    other_cards_resp = requests.get(
        f"{BASE}/showrooms/{other_showroom['id']}/card-accounts",
        headers=auth("token")).json()
    items = data_list(other_cards_resp)
    if items:
        v["other_showroom_card_id"] = items[0]["id"]

if v["other_showroom_card_id"]:
    resp, body, ok = test(63, "Staff: wrong showroom card = 422", "POST",
        "/card-entries", 422, tok="staff_token",
        json={"entry_date": "2026-04-11", "card_account_id": v["other_showroom_card_id"],
              "amount": 100, "notes": "wrong showroom"})
else:
    results.append((63, "Staff: wrong showroom card = 422", "POST", 422, "SKIP", "SKIP"))
    print("  [SKIP] #63 No other-showroom card available")

resp, body, ok = test(64, "Validation: non-existent card_id = 422", "POST",
    "/card-entries", 422, tok="staff_token",
    json={"entry_date": "2026-04-11", "card_account_id": 99999, "amount": 100, "notes": "bad id"})

all_cash = requests.get(f"{BASE}/cash-entries", headers=auth("token")).json()
locked_cash = next((e["id"] for e in data_list(all_cash) if e.get("is_locked")), None)
if locked_cash:
    resp, body, ok = test(65, "Staff: edit locked entry = 403", "PUT",
        f"/cash-entries/{locked_cash}", 403, tok="staff_token",
        json={"cash_amount": 99999})
    resp, body, ok = test(66, "Admin CAN edit locked entry", "PUT",
        f"/cash-entries/{locked_cash}", 200, tok="token",
        json={"cash_amount": 99999, "notes": "Admin edited locked"})
else:
    for n, name in [(65, "Staff: edit locked entry = 403"), (66, "Admin CAN edit locked entry")]:
        results.append((n, name, "PUT", 200, "SKIP", "SKIP"))
    print("  [SKIP] #65,66 No locked cash entry found")

resp, body, ok = test(67, "Self-tx: same from=to card = 422", "POST",
    "/self-transactions", 422, tok="token",
    json={"from_card_account_id": v.get("from_card_id"),
          "to_card_account_id": v.get("from_card_id"),
          "amount": 100, "notes": "same card"})

from_bal_now = requests.get(
    f"{BASE}/showrooms/{v.get('showroom_id')}/card-accounts",
    headers=auth("token")).json()
from_current = next((float(c["current_balance"]) for c in data_list(from_bal_now)
                     if c["id"] == v.get("from_card_id")), 0)
resp, body, ok = test(68, "Self-tx: overdraft = 422", "POST",
    "/self-transactions", 422, tok="token",
    json={"from_card_account_id": v.get("from_card_id"),
          "to_card_account_id": v.get("to_card_id"),
          "amount": from_current + 1000000, "notes": "overdraft"})

resp, body, ok = test(69, "Login: wrong password = 401", "POST", "/login", 401,
    json={"email": "admin@admin.com", "password": "wrongpassword"})

resp, body, ok = test(70, "Unauthenticated GET /showrooms = 401", "GET", "/showrooms", 401)

resp, body, ok = test(71, "Staff GET /showrooms = 403", "GET", "/showrooms", 403, tok="staff_token")

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("RESULTS SUMMARY")
print("=" * 70)
print(f"{'#':<6} {'Name':<50} {'Exp':>5} {'Got':>5}  Result")
print("-" * 70)
passes = fails = skips = 0
for row in results:
    num, name, method, exp, got, result = row
    if result == "PASS":
        passes += 1; marker = "OK"
    elif result == "SKIP":
        skips += 1; marker = "--"
    else:
        fails += 1; marker = "FAIL"
    print(f"{str(num):<6} {name[:50]:<50} {str(exp):>5} {str(got):>5}  {marker}")
print("-" * 70)
print(f"TOTAL: {passes} PASSED  |  {fails} FAILED  |  {skips} SKIPPED  |  {passes+fails+skips} total")

print("\n── SAVED STATE ──")
for k, val in sorted(v.items()):
    if k not in ("other_showroom",):
        print(f"  {k} = {val}")
