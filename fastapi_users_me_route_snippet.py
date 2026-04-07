# Paste into your FastAPI users router (same file as list_users).
# Router should be included with prefix="/users" so this becomes GET /users/me
#
# Prerequisites:
#   1. A dependency that returns the ORM User for the JWT in Authorization: Bearer <token>
#      (common names: get_current_user, get_current_active_user, get_current_user_optional)
#   2. Your existing _user_out(user) helper — ensure it includes fields the app expects:
#        - user_id or userID or userId (mobile UserMe)
#        - username or name, email
#        - role and/or is_event_poster (for "Event Poster" tab in the app)
#
# If you do not have a "current user" dependency yet, add one in auth/deps that:
#   - reads the Bearer token, decodes JWT sub / user id, loads User from DB, returns it.

# --- add these imports at top of file if missing ---
# from fastapi import Depends
# from sqlalchemy.orm import Session

# Example route (rename Depends(...) to match YOUR project):

# @router.get("/me")
# def read_users_me(
#     current_user: User = Depends(get_current_active_user),  # <-- change to your dependency
# ):
#     """Current authenticated user (mobile app GET /users/me)."""
#     return _user_out(current_user)


# ---------------------------------------------------------------------------
# If you need a minimal get_current_user (adjust imports to your models/JWT):
# ---------------------------------------------------------------------------
# from fastapi import Depends, HTTPException, status
# from fastapi.security import OAuth2PasswordBearer
# from jose import JWTError, jwt
#
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")  # match your token URL
#
# def get_current_user(
#     db: Session = Depends(get_db),
#     token: str = Depends(oauth2_scheme),
# ) -> User:
#     credentials_exception = HTTPException(
#         status_code=status.HTTP_401_UNAUTHORIZED,
#         detail="Could not validate credentials",
#         headers={"WWW-Authenticate": "Bearer"},
#     )
#     try:
#         payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
#         sub: str | None = payload.get("sub")
#         if sub is None:
#             raise credentials_exception
#     except JWTError:
#         raise credentials_exception
#     user = db.query(User).filter(User.userID == sub).first()  # or int(sub) if numeric
#     if user is None:
#         raise credentials_exception
#     return user
