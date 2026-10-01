import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { OrbitControls, Instance, Instances } from '@react-three/drei';
import * as THREE from 'three';

const NUM_NODES = 100;
const nodesData = Array.from({ length: NUM_NODES }).map(() => ({
  position: [
    (Math.random() - 0.5) * 8,
    (Math.random() - 0.5) * 2,
    (Math.random() - 0.5) * 8
  ] as [number, number, number],
  scale: Math.random() * 0.5 + 0.1,
  color: Math.random() > 0.8 ? '#22D3EE' : '#10182B',
}));

export const ActivityMatrix: React.FC = () => {
  const groupRef = useRef<THREE.Group>(null);

  useFrame(({ clock }) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = clock.getElapsedTime() * 0.02;
    }
  });

  return (
    <>
      <ambientLight intensity={0.5} />
      <directionalLight position={[10, 10, 10]} intensity={1} color="#4F7CFF" />
      <OrbitControls enablePan={false} enableZoom={true} minDistance={5} maxDistance={15} />

      <group ref={groupRef}>
        <Instances range={NUM_NODES} material={new THREE.MeshStandardMaterial({ roughness: 0.1, emissiveIntensity: 2 })}>
          <boxGeometry args={[0.2, 2, 0.2]} />
          <meshStandardMaterial />
          {nodesData.map((node, i) => (
            <Instance
              key={i}
              position={node.position}
              scale={[1, node.scale, 1]}
              color={node.color}
            />
          ))}
        </Instances>

        {/* Base Grid */}
        <gridHelper args={[10, 20, '#22D3EE', '#10182B']} position={[0, -1, 0]} />
      </group>
    </>
  );
};
