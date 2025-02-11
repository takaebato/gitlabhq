export const HTTP_STATUS_ABORTED = 0;
export const HTTP_STATUS_CREATED = 201;
export const HTTP_STATUS_ACCEPTED = 202;
export const HTTP_STATUS_NON_AUTHORITATIVE_INFORMATION = 203;
export const HTTP_STATUS_NO_CONTENT = 204;
export const HTTP_STATUS_RESET_CONTENT = 205;
export const HTTP_STATUS_PARTIAL_CONTENT = 206;
export const HTTP_STATUS_MULTI_STATUS = 207;
export const HTTP_STATUS_ALREADY_REPORTED = 208;
export const HTTP_STATUS_IM_USED = 226;
export const HTTP_STATUS_METHOD_NOT_ALLOWED = 405;
export const HTTP_STATUS_CONFLICT = 409;
export const HTTP_STATUS_GONE = 410;
export const HTTP_STATUS_PAYLOAD_TOO_LARGE = 413;
export const HTTP_STATUS_UNPROCESSABLE_ENTITY = 422;
export const HTTP_STATUS_TOO_MANY_REQUESTS = 429;
export const HTTP_STATUS_BAD_REQUEST = 400;
export const HTTP_STATUS_UNAUTHORIZED = 401;
export const HTTP_STATUS_FORBIDDEN = 403;

// TODO move the rest of the status codes to primitive constants
// https://docs.gitlab.com/ee/development/fe_guide/style/javascript.html#export-constants-as-primitives
const httpStatusCodes = {
  OK: 200,
  NOT_FOUND: 404,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
};

export const successCodes = [
  httpStatusCodes.OK,
  HTTP_STATUS_CREATED,
  HTTP_STATUS_ACCEPTED,
  HTTP_STATUS_NON_AUTHORITATIVE_INFORMATION,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_RESET_CONTENT,
  HTTP_STATUS_PARTIAL_CONTENT,
  HTTP_STATUS_MULTI_STATUS,
  HTTP_STATUS_ALREADY_REPORTED,
  HTTP_STATUS_IM_USED,
];

export default httpStatusCodes;
