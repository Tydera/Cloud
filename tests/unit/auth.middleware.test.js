const jwt = require('jsonwebtoken');
const { authenticate } = require('../../src/middleware/auth');

describe('Authentication Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      headers: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();
  });

  it('should return 401 if no authorization header', async () => {
    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Authentication required',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 401 if authorization header is invalid', async () => {
    req.headers.authorization = 'Invalid token';

    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 401 if token is invalid', async () => {
    req.headers.authorization = 'Bearer invalid.token.here';

    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('should set req.user and call next if token is valid', async () => {
    const payload = {
      id: '123',
      email: 'test@example.com',
      role: 'user',
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET || 'your-secret-key');
    req.headers.authorization = `Bearer ${token}`;

    await authenticate(req, res, next);

    expect(req.user).toBeDefined();
    expect(req.user.id).toBe(payload.id);
    expect(req.user.email).toBe(payload.email);
    expect(next).toHaveBeenCalled();
  });
});
