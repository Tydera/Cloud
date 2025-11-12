const { authorize } = require('../../src/middleware/authorization');

describe('Authorization Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      user: null,
      path: '/test',
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();
  });

  it('should return 401 if no user in request', () => {
    const middleware = authorize(['admin']);

    middleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 403 if user role is not allowed', () => {
    req.user = {
      id: '123',
      email: 'test@example.com',
      role: 'user',
    };

    const middleware = authorize(['admin']);

    middleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Forbidden',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('should call next if user role is allowed', () => {
    req.user = {
      id: '123',
      email: 'admin@example.com',
      role: 'admin',
    };

    const middleware = authorize(['admin']);

    middleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should call next if user role is in allowed roles', () => {
    req.user = {
      id: '123',
      email: 'user@example.com',
      role: 'user',
    };

    const middleware = authorize(['user', 'admin']);

    middleware(req, res, next);

    expect(next).toHaveBeenCalled();
  });
});
