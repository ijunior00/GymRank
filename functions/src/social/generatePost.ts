import { db, Timestamp } from '../admin';

export type AutoPostType =
  | 'streakMilestone'
  | 'xpMilestone'
  | 'levelUp'
  | 'personalRecord'
  | 'challengeCompleted';

interface AutoPostInput {
  userId: string;
  authorName: string;
  authorPhotoUrl: string | null;
  type: AutoPostType;
  text: string;
  imageUrl?: string | null;
}

/** Cria um post automático no feed (ver seção "Feed Social" do produto). */
export async function generateAutoPost(input: AutoPostInput): Promise<void> {
  await db.collection('posts').add({
    userId: input.userId,
    authorName: input.authorName,
    authorPhotoUrl: input.authorPhotoUrl,
    type: input.type,
    text: input.text,
    imageUrl: input.imageUrl ?? null,
    likeCount: 0,
    commentCount: 0,
    shareCount: 0,
    createdAt: Timestamp.now(),
  });
}
