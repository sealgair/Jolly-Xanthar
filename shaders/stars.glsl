extern vec4 quatAngle;
attribute vec2 VertexZPosition;

vec4 quat_conj(vec4 q) {
  return vec4(-q.x, -q.y, -q.z, q.w);
}

vec3 rotate_vertex_position(vec3 position) {
  vec4 q = quatAngle;
  vec3 v = position.xyz;
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vec3 pos = vec3(vertex_position.x, vertex_position.y, VertexZPosition);
    vec3 r = rotate_vertex_position(pos);
    vec2 b = vec2(r.x / -r.z, r.y / -r.z);
    b = (b + vec2(1, 1)) * .5 * love_ScreenSize.xy;
    return transform_projection * vec4(b.x, b.y, 1, 1);
}