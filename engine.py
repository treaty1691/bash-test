import math
import copy

# Piece encoding
# White: 'P','N','B','R','Q','K'
# Black: 'p','n','b','r','q','k'
# Empty: '.'

START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w"

PIECE_VALUES = {
    'P': 100, 'N': 320, 'B': 330, 'R': 500, 'Q': 900, 'K': 20000,
    'p': -100, 'n': -320, 'b': -330, 'r': -500, 'q': -900, 'k': -20000
}

DIRECTIONS = {
    'P': [(-1, 0), (-1, -1), (-1, 1)],
    'p': [(1, 0), (1, -1), (1, 1)],
    'N': [(-2, -1), (-2, 1), (-1, -2), (-1, 2),
          (1, -2), (1, 2), (2, -1), (2, 1)],
    'B': [(-1, -1), (-1, 1), (1, -1), (1, 1)],
    'R': [(-1, 0), (1, 0), (0, -1), (0, 1)],
    'Q': [(-1, -1), (-1, 1), (1, -1), (1, 1),
          (-1, 0), (1, 0), (0, -1), (0, 1)],
    'K': [(-1, -1), (-1, 1), (1, -1), (1, 1),
          (-1, 0), (1, 0), (0, -1), (0, 1)]
}

def parse_fen(fen):
    board_part, side = fen.split()
    rows = board_part.split('/')
    board = []
    for r in rows:
        row = []
        for ch in r:
            if ch.isdigit():
                row.extend(['.'] * int(ch))
            else:
                row.append(ch)
        board.append(row)
    return board, side

def board_to_fen(board, side):
    rows = []
    for r in board:
        s = ""
        empty = 0
        for ch in r:
            if ch == '.':
                empty += 1
            else:
                if empty:
                    s += str(empty)
                    empty = 0
                s += ch
        if empty:
            s += str(empty)
        rows.append(s)
    return "/".join(rows) + " " + side

def in_bounds(r, c):
    return 0 <= r < 8 and 0 <= c < 8

def is_white(piece):
    return piece.isupper()

def is_black(piece):
    return piece.islower()

def generate_moves(board, side):
    moves = []
    for r in range(8):
        for c in range(8):
            piece = board[r][c]
            if piece == '.':
                continue
            if side == 'w' and not is_white(piece):
                continue
            if side == 'b' and not is_black(piece):
                continue
            moves.extend(generate_piece_moves(board, r, c, side))
    # Filter out moves that leave king in check
    legal = []
    for move in moves:
        b2, s2 = make_move(board, side, move, validate=False)
        if not is_in_check(b2, side):
            legal.append(move)
    return legal

def generate_piece_moves(board, r, c, side):
    piece = board[r][c]
    moves = []
    if piece.upper() == 'P':
        moves.extend(generate_pawn_moves(board, r, c, side))
    elif piece.upper() == 'N':
        moves.extend(generate_leaper_moves(board, r, c, side, 'N'))
    elif piece.upper() in ['B', 'R', 'Q']:
        moves.extend(generate_slider_moves(board, r, c, side, piece.upper()))
    elif piece.upper() == 'K':
        moves.extend(generate_leaper_moves(board, r, c, side, 'K'))
    return moves

def generate_pawn_moves(board, r, c, side):
    moves = []
    piece = board[r][c]
    dirs = DIRECTIONS[piece]
    forward = dirs[0]
    fr, fc = r + forward[0], c + forward[1]
    # Single push
    if in_bounds(fr, fc) and board[fr][fc] == '.':
        moves.append(((r, c), (fr, fc)))
        # Double push
        if (side == 'w' and r == 6) or (side == 'b' and r == 1):
            fr2 = fr + forward[0]
            if in_bounds(fr2, fc) and board[fr2][fc] == '.':
                moves.append(((r, c), (fr2, fc)))
    # Captures
    for cap in dirs[1:]:
        cr, cc = r + cap[0], c + cap[1]
        if not in_bounds(cr, cc):
            continue
        target = board[cr][cc]
        if side == 'w' and is_black(target):
            moves.append(((r, c), (cr, cc)))
        if side == 'b' and is_white(target):
            moves.append(((r, c), (cr, cc)))
    return moves

def generate_leaper_moves(board, r, c, side, kind):
    moves = []
    piece = board[r][c]
    for dr, dc in DIRECTIONS[kind]:
        nr, nc = r + dr, c + dc
        if not in_bounds(nr, nc):
            continue
        target = board[nr][nc]
        if target == '.' or (side == 'w' and is_black(target)) or (side == 'b' and is_white(target)):
            moves.append(((r, c), (nr, nc)))
    return moves

def generate_slider_moves(board, r, c, side, kind):
    moves = []
    for dr, dc in DIRECTIONS[kind]:
        nr, nc = r + dr, c + dc
        while in_bounds(nr, nc):
            target = board[nr][nc]
            if target == '.':
                moves.append(((r, c), (nr, nc)))
            else:
                if (side == 'w' and is_black(target)) or (side == 'b' and is_white(target)):
                    moves.append(((r, c), (nr, nc)))
                break
            nr += dr
            nc += dc
    return moves

def find_king(board, side):
    king = 'K' if side == 'w' else 'k'
    for r in range(8):
        for c in range(8):
            if board[r][c] == king:
                return r, c
    return None

def is_in_check(board, side):
    king_pos = find_king(board, side)
    if not king_pos:
        return True
    kr, kc = king_pos
    enemy = 'b' if side == 'w' else 'w'
    # Generate enemy moves ignoring check legality
    for r in range(8):
        for c in range(8):
            piece = board[r][c]
            if piece == '.':
                continue
            if enemy == 'w' and not is_white(piece):
                continue
            if enemy == 'b' and not is_black(piece):
                continue
            for move in generate_piece_moves_raw(board, r, c, enemy):
                (_, _), (tr, tc) = move
                if tr == kr and tc == kc:
                    return True
    return False

def generate_piece_moves_raw(board, r, c, side):
    # Like generate_piece_moves but without self-check filtering
    piece = board[r][c]
    moves = []
    if piece.upper() == 'P':
        moves.extend(generate_pawn_moves(board, r, c, side))
    elif piece.upper() == 'N':
        moves.extend(generate_leaper_moves(board, r, c, side, 'N'))
    elif piece.upper() in ['B', 'R', 'Q']:
        moves.extend(generate_slider_moves(board, r, c, side, piece.upper()))
    elif piece.upper() == 'K':
        moves.extend(generate_leaper_moves(board, r, c, side, 'K'))
    return moves

def make_move(board, side, move, validate=True):
    (r1, c1), (r2, c2) = move
    piece = board[r1][c1]
    new_board = copy.deepcopy(board)
    new_board[r1][c1] = '.'
    # Promotion to queen if pawn reaches last rank
    if piece == 'P' and r2 == 0:
        new_board[r2][c2] = 'Q'
    elif piece == 'p' and r2 == 7:
        new_board[r2][c2] = 'q'
    else:
        new_board[r2][c2] = piece
    new_side = 'b' if side == 'w' else 'w'
    if validate and is_in_check(new_board, side):
        return None, side
    return new_board, new_side

def evaluate(board):
    score = 0
    for r in range(8):
        for c in range(8):
            piece = board[r][c]
            if piece in PIECE_VALUES:
                score += PIECE_VALUES[piece]
    return score

def is_game_over(board, side):
    moves = generate_moves(board, side)
    if moves:
        return False, None
    if is_in_check(board, side):
        return True, 'checkmate'
    else:
        return True, 'stalemate'

def alphabeta(board, side, depth, alpha, beta):
    over, result = is_game_over(board, side)
    if depth == 0 or over:
        if over:
            if result == 'checkmate':
                return (-math.inf if side == 'w' else math.inf), None
            else:
                return 0, None
        return evaluate(board), None

    best_move = None
    moves = generate_moves(board, side)
    if side == 'w':
        max_eval = -math.inf
        for move in moves:
            b2, s2 = make_move(board, side, move)
            if b2 is None:
                continue
            eval_score, _ = alphabeta(b2, s2, depth - 1, alpha, beta)
            if eval_score > max_eval:
                max_eval = eval_score
                best_move = move
            alpha = max(alpha, eval_score)
            if beta <= alpha:
                break
        return max_eval, best_move
    else:
        min_eval = math.inf
        for move in moves:
            b2, s2 = make_move(board, side, move)
            if b2 is None:
                continue
            eval_score, _ = alphabeta(b2, s2, depth - 1, alpha, beta)
            if eval_score < min_eval:
                min_eval = eval_score
                best_move = move
            beta = min(beta, eval_score)
            if beta <= alpha:
                break
        return min_eval, best_move

def print_board(board):
    print("  +-----------------+")
    for r in range(8):
        print(8 - r, "|", end=" ")
        for c in range(8):
            print(board[r][c], end=" ")
        print("|")
    print("  +-----------------+")
    print("    a b c d e f g h")

def parse_move_str(move_str):
    # e2e4
    if len(move_str) != 4:
        return None
    files = "abcdefgh"
    ranks = "12345678"
    f1, r1, f2, r2 = move_str[0], move_str[1], move_str[2], move_str[3]
    if f1 not in files or f2 not in files or r1 not in ranks or r2 not in ranks:
        return None
    c1 = files.index(f1)
    c2 = files.index(f2)
    r1 = 8 - int(r1)
    r2 = 8 - int(r2)
    return (r1, c1), (r2, c2)

def move_to_str(move):
    (r1, c1), (r2, c2) = move
    files = "abcdefgh"
    ranks = "12345678"
    return f"{files[c1]}{8-r1}{files[c2]}{8-r2}"

def main():
    board, side = parse_fen(START_FEN)
    human_side = 'w'  # you play White
    depth = 3         # search depth

    while True:
        print_board(board)
        over, result = is_game_over(board, side)
        if over:
            if result == 'checkmate':
                print("Checkmate! " + ("Black wins." if side == 'w' else "White wins."))
            else:
                print("Stalemate.")
            break

        if side == human_side:
            print("Your move (e.g., e2e4):")
            move_str = input().strip()
            move = parse_move_str(move_str)
            if not move:
                print("Invalid format.")
                continue
            legal_moves = generate_moves(board, side)
            if move not in legal_moves:
                print("Illegal move.")
                continue
            board, side = make_move(board, side, move)
        else:
            print("Engine thinking...")
            _, best_move = alphabeta(board, side, depth, -math.inf, math.inf)
            if best_move is None:
                # no legal moves
                over, result = is_game_over(board, side)
                if over:
                    if result == 'checkmate':
                        print("Checkmate!")
                    else:
                        print("Stalemate.")
                    break
            print("Engine plays:", move_to_str(best_move))
            board, side = make_move(board, side, best_move)

if __name__ == "__main__":
    main()
.
