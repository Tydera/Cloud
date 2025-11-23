const { validateRequest } = require('../../src/middleware/validator');
const Joi = require('joi');

describe('Validator Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      body: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();
  });

  it('should return 400 if validation fails', () => {
    const schema = Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().min(8).required(),
    });

    req.body = {
      email: 'invalid-email',
    };

    const middleware = validateRequest(schema);
    middleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Validation error',
        details: expect.any(Array),
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('should call next if validation passes', () => {
    const schema = Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().min(8).required(),
    });

    req.body = {
      email: 'test@example.com',
      password: 'password123',
    };

    const middleware = validateRequest(schema);
    middleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should strip unknown fields', () => {
    const schema = Joi.object({
      email: Joi.string().email().required(),
    });

    req.body = {
      email: 'test@example.com',
      unknownField: 'value',
    };

    const middleware = validateRequest(schema);
    middleware(req, res, next);

    expect(req.body).toEqual({ email: 'test@example.com' });
    expect(next).toHaveBeenCalled();
  });
});
