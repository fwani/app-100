from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.deps.auth import get_current_user, ensure_room_member, get_room_or_404
from app.deps.common import get_db
from app.models.post import Post, Comment
from app.schemas.post import PostOut, PostIn, CommentIn, CommentOut

router = APIRouter()


@router.get("/{room_id}/posts", response_model=list[PostOut])
def list_posts(room_id: int,
               db: Session = Depends(get_db),
               user=Depends(get_current_user),
               limit: int = Query(30, le=100),
               offset: int = 0):
    get_room_or_404(room_id, db)
    ensure_room_member(room_id, user, db)
    q = (db.query(Post)
         .filter(Post.room_id == room_id)
         .order_by(Post.created_at.desc())
         .limit(limit).offset(offset))
    return q.all()


@router.post("/{room_id}/posts", response_model=PostOut)
def create_post(room_id: int, payload: PostIn,
                db: Session = Depends(get_db),
                user=Depends(get_current_user)):
    get_room_or_404(room_id, db)
    ensure_room_member(room_id, user, db)
    p = Post(room_id=room_id, author_id=user.id, text=payload.text,
             photos=payload.photos or [], mood=payload.mood, shot_at=payload.shot_at)
    db.add(p);
    db.commit();
    db.refresh(p)
    return p


@router.get("/{room_id}/comments", response_model=list[CommentOut])
def list_comments(room_id: int, post_id: int,
                  db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    return (db.query(Comment)
            .filter(Comment.post_id == post_id)
            .order_by(Comment.created_at.asc())
            .all())


@router.post("/{room_id}/comments", response_model=CommentOut)
def add_comment(room_id: int, payload: CommentIn,
                db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    c = Comment(post_id=payload.post_id, author_id=user.id, text=payload.text)
    db.add(c);
    db.commit();
    db.refresh(c)
    return c
